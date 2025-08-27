import Foundation
import Combine
import SwiftUI

class YTDLPService {
    private let preferences = AppPreferences.shared
    
    // Find ffmpeg installation
    private func findFFmpeg() -> String? {
        // FIRST: Check for bundled version in app Resources
        if let bundledPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil, inDirectory: "bin") {
            if FileManager.default.fileExists(atPath: bundledPath) {
                DebugLogger.shared.log("Using bundled ffmpeg", level: .success)
                return bundledPath
            }
        }
        
        let possiblePaths = [
            "/opt/homebrew/bin/ffmpeg",     // Homebrew on Apple Silicon
            "/usr/local/bin/ffmpeg",        // Homebrew on Intel
            "/usr/bin/ffmpeg"               // System install
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                DebugLogger.shared.log("Found ffmpeg at: \(path)", level: .success)
                return path
            }
        }
        
        // Try using 'which' command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["ffmpeg"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    DebugLogger.shared.log("Found ffmpeg via which: \(path)", level: .success)
                    return path
                }
            }
        } catch {
            DebugLogger.shared.log("Failed to find ffmpeg: \(error)", level: .warning)
        }
        
        return nil
    }
    
    // This method searches common locations where yt-dlp might be installed
    // It's like having multiple backup plans - if it's not in the first place,
    // check the second, then the third, and so on
    private func findYTDLP() -> String? {
        // FIRST: Check for bundled version in app Resources
        if let bundledPath = Bundle.main.path(forResource: "yt-dlp", ofType: nil, inDirectory: "bin") {
            if FileManager.default.fileExists(atPath: bundledPath) {
                DebugLogger.shared.log("Using bundled yt-dlp", level: .success)
                return bundledPath
            }
        }
        
        // List of common installation locations for yt-dlp on macOS
        let possiblePaths = [
            "/opt/homebrew/bin/yt-dlp",     // Homebrew on Apple Silicon
            "/usr/local/bin/yt-dlp",        // Homebrew on Intel or manual install
            "/usr/bin/yt-dlp",              // System-wide install (rare on macOS)
            "/opt/local/bin/yt-dlp",        // MacPorts
            "\(NSHomeDirectory())/bin/yt-dlp", // User's home bin directory
            "\(NSHomeDirectory())/.local/bin/yt-dlp" // Python pip user install
        ]
        
        // Check each path to see if yt-dlp exists there
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                DebugLogger.shared.log("Found yt-dlp at: \(path)", level: .success)
                return path
            }
        }
        
        // If not found in common locations, try using 'which' command
        // This is like asking the system "hey, do you know where yt-dlp is?"
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["yt-dlp"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    DebugLogger.shared.log("Found yt-dlp via which: \(path)", level: .success)
                    return path
                }
            }
        } catch {
            // If 'which' fails, that's okay - we'll return nil
        }
        
        DebugLogger.shared.log("yt-dlp not found in any standard location", level: .error)
        return nil
    }
    
    // Store the path to yt-dlp - adjust this based on what 'which yt-dlp' showed you
    private let ytdlpPath = "/opt/homebrew/bin/yt-dlp"
    // Cache the path after finding it once
    private var cachedYTDLPPath: String?

    // Modified findYTDLP that uses the cache
    private func getYTDLPPath() throws -> String {
        // If we've already found it, use the cached path
        if let cached = cachedYTDLPPath {
            return cached
        }
        
        // Otherwise, find it and cache the result
        guard let path = findYTDLP() else {
            throw YTDLPError.ytdlpNotFound
        }
        
        cachedYTDLPPath = path
        return path
    }
    
    // Test if yt-dlp is installed and working
    func getVersion() async throws -> String {
        let ytdlpPath = try getYTDLPPath()  // This will find it or use cache
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        process.arguments = ["--version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? "Unknown version"
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // Old download method - kept for compatibility but shouldn't be used
    func downloadVideo(task: DownloadTask) async throws {
        guard let ytdlpPath = findYTDLP() else {
            DebugLogger.shared.log("yt-dlp not found in any standard location", level: .error)
            throw YTDLPError.ytdlpNotFound
        }
        
        DebugLogger.shared.log("Starting download for: \(task.videoInfo.title)", level: .info)
        DebugLogger.shared.log("Using yt-dlp at: \(ytdlpPath)", level: .info)
        
        // Update the task state
        await MainActor.run {
            task.state = .preparing
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        
        // Build the arguments for yt-dlp
        var formatArg = task.selectedFormat.format_id
        
        // If this format needs audio merging, tell yt-dlp to grab audio too
        if task.selectedFormat.needsAudioMerge {
            // For Twitter/X videos, we need to be more specific about audio selection
            if task.videoInfo.webpage_url.contains("twitter.com") || task.videoInfo.webpage_url.contains("x.com") {
                // Twitter videos often need specific audio format selection
                formatArg = "\(task.selectedFormat.format_id)+bestaudio[ext=mp4]/\(task.selectedFormat.format_id)+bestaudio/best"
            } else {
                // Standard approach for other sites
                formatArg = "\(task.selectedFormat.format_id)+bestaudio"
            }
        }
        
        let arguments = [
            "-f", formatArg,                      // Format selection
            "-o", task.outputURL.path,            // Where to save the file
            "--newline",                          // Output progress on separate lines
            "--progress",                         // Show progress info
            "--no-part",                          // Don't use .part files
            "--merge-output-format", "mp4",      // Ensure mp4 output when merging
            "--verbose",                          // Verbose output for debugging
            task.videoInfo.webpage_url            // The URL to download
        ]
        
        process.arguments = arguments
        
        // Log the full command for debugging
        let fullCommand = "\(ytdlpPath) \(arguments.joined(separator: " "))"
        DebugLogger.shared.log("Executing command", level: .command, details: fullCommand)
        
        // Set up pipes for output and errors separately
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        DebugLogger.shared.log("Process pipes configured", level: .info)
        
        // Store the process so we can cancel it if needed
        task.process = process
        
        // Read standard output
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let line = String(data: data, encoding: .utf8) {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedLine.isEmpty {
                    if trimmedLine.contains("ERROR") {
                        DebugLogger.shared.log("yt-dlp error", level: .error, details: trimmedLine)
                    } else if trimmedLine.contains("WARNING") {
                        DebugLogger.shared.log("yt-dlp warning", level: .warning, details: trimmedLine)
                    } else if trimmedLine.contains("[download]") {
                        // Parse progress but don't log every update
                        self.parseProgress(line: trimmedLine, for: task)
                    } else {
                        DebugLogger.shared.log("yt-dlp", level: .info, details: trimmedLine)
                    }
                }
            }
        }
        
        // Read stderr output (may contain debug info, not just errors)
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let errorLine = String(data: data, encoding: .utf8) {
                let trimmedError = errorLine.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedError.isEmpty {
                    // Categorize stderr output
                    if trimmedError.contains("[debug]") {
                        DebugLogger.shared.log("Debug", level: .info, details: trimmedError)
                    } else if trimmedError.contains("WARNING") {
                        DebugLogger.shared.log("Warning", level: .warning, details: trimmedError)
                    } else if trimmedError.contains("ERROR") || trimmedError.contains("error:") {
                        DebugLogger.shared.log("Error", level: .error, details: trimmedError)
                    } else {
                        DebugLogger.shared.log("Info", level: .info, details: trimmedError)
                    }
                }
            }
        }
        
        // Update state to downloading
        await MainActor.run {
            task.state = .downloading
        }
        
        // Start the download with timeout
        do {
            // Register with ProcessManager
            await ProcessManager.shared.register(process)
            
            try process.run()
            DebugLogger.shared.log("Download process started", level: .success)
            
            // Create timeout task (10 minutes for downloads)
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 600_000_000_000) // 10 minutes
                
                if process.isRunning {
                    PersistentDebugLogger.shared.log(
                        "Download timed out after 10 minutes",
                        level: .error,
                        details: "URL: \(task.videoInfo.webpage_url)"
                    )
                    await ProcessManager.shared.terminate(process)
                    await MainActor.run {
                        task.state = .failed("Download timed out")
                    }
                }
            }
            
            // Wait for process to complete
            await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    process.waitUntilExit()
                    continuation.resume()
                }
            }
            
            // Cancel timeout if process completed
            timeoutTask.cancel()
            
        } catch {
            DebugLogger.shared.log("Failed to start download", level: .error, details: error.localizedDescription)
            // Clean up on error
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            process.cleanupPipes()
            await ProcessManager.shared.unregister(process)
            throw error
        }
        
        // Clean up after normal completion
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        process.cleanupPipes()
        await ProcessManager.shared.unregister(process)
        
        // Check if it succeeded
        if process.terminationStatus == 0 {
            DebugLogger.shared.log("Download completed successfully", level: .success)
            await MainActor.run {
                task.state = .completed
                task.progress = 100.0
            }
        } else if process.terminationStatus == 15 {
            // 15 is SIGTERM - user cancelled
            DebugLogger.shared.log("Download cancelled by user", level: .warning)
            await MainActor.run {
                task.state = .cancelled
            }
        } else {
            let errorMsg = "Download failed with exit code: \(process.terminationStatus)"
            DebugLogger.shared.log(errorMsg, level: .error)
            
            // Try to read any remaining error output
            let finalErrorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if let finalError = String(data: finalErrorData, encoding: .utf8), !finalError.isEmpty {
                DebugLogger.shared.log("Error details", level: .error, details: finalError)
            }
            
            await MainActor.run {
                task.state = .failed(errorMsg)
            }
        }
    }

    // Parse yt-dlp's progress output
    private func parseProgress(line: String, for task: DownloadTask) {
        // yt-dlp outputs progress in various formats
        // We need to parse lines that look like:
        // "[download]  45.2% of 120.5MiB at 2.5MiB/s ETA 00:30"
        
        Task { @MainActor in
            // Look for percentage
            if let percentRange = line.range(of: #"(\d+\.?\d*)%"#, options: .regularExpression) {
                let percentString = String(line[percentRange]).replacingOccurrences(of: "%", with: "")
                if let percent = Double(percentString) {
                    task.progress = percent
                }
            }
            
            // Look for speed
            if let speedRange = line.range(of: #"at\s+([\d.]+\w+/s)"#, options: .regularExpression) {
                let speedPart = String(line[speedRange])
                task.speed = speedPart.replacingOccurrences(of: "at ", with: "")
            }
            
            // Look for ETA
            if let etaRange = line.range(of: #"ETA\s+([\d:]+)"#, options: .regularExpression) {
                let etaPart = String(line[etaRange])
                task.eta = etaPart.replacingOccurrences(of: "ETA ", with: "")
            }
            
            // Check if we're merging
            if line.contains("[ffmpeg]") || line.contains("Merging") {
                task.state = .merging
            }
        }
    }
    
    // Now the real metadata fetching function
    // Check if URL is a playlist and get basic info
    func checkForPlaylist(urlString: String) async throws -> (isPlaylist: Bool, count: Int?) {
        let ytdlpPath = try getYTDLPPath()
        
        PersistentDebugLogger.shared.log("Checking if URL is playlist: \(urlString)", level: .info)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        
        // Use --dump-single-json with --flat-playlist to get complete playlist info
        process.arguments = [
            "--dump-single-json",
            "--flat-playlist",
            urlString
        ]
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: data, encoding: .utf8),
           let jsonData = output.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    // Check if it's a playlist by looking at _type field
                    if let type = json["_type"] as? String, type == "playlist" {
                        let count = json["playlist_count"] as? Int ?? json["n_entries"] as? Int ?? 0
                        let title = json["title"] as? String ?? json["playlist_title"] as? String ?? "Untitled Playlist"
                        PersistentDebugLogger.shared.log("Playlist detected: \(title) with \(count) videos", level: .success)
                        return (true, count)
                    }
                    
                    // Not a playlist but a single video
                    if let _ = json["id"] as? String {
                        PersistentDebugLogger.shared.log("Single video detected", level: .info)
                        return (false, nil)
                    }
                }
            } catch {
                PersistentDebugLogger.shared.log("Failed to parse playlist check JSON: \(error)", level: .warning)
            }
        }
        
        PersistentDebugLogger.shared.log("Not a playlist or single video", level: .info)
        return (false, nil)
    }
    
    // Fetch full playlist information with all videos
    func fetchPlaylistInfo(urlString: String, limit: Int? = nil) async throws -> PlaylistConfirmationView.PlaylistInfo {
        let ytdlpPath = try getYTDLPPath()
        
        DebugLogger.shared.log("Fetching playlist info for: \(urlString)", level: .info)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        
        var args = [
            "--dump-single-json",
            "--flat-playlist",
            urlString
        ]
        
        // Add playlist range if specified
        if let limit = limit {
            args.insert(contentsOf: ["--playlist-items", "1-\(limit)"], at: 0)
        }
        
        process.arguments = args
        
        let pipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = pipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var videos: [VideoInfo] = []
        var playlistTitle = "Unknown Playlist"
        var playlistUploader: String?
        var playlistId: String?
        
        // Parse single JSON output for playlist
        if let output = String(data: data, encoding: .utf8),
           let jsonData = output.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    // Extract playlist metadata
                    playlistTitle = json["title"] as? String ?? json["playlist_title"] as? String ?? "Unknown Playlist"
                    playlistUploader = json["uploader"] as? String ?? json["playlist_uploader"] as? String
                    playlistId = json["id"] as? String ?? json["playlist_id"] as? String
                    
                    // Extract video entries
                    if let entries = json["entries"] as? [[String: Any]] {
                        for entry in entries {
                            if let title = entry["title"] as? String,
                               let videoId = entry["id"] as? String {
                                
                                // Construct URL based on the extractor
                                let url = entry["url"] as? String ?? 
                                         entry["webpage_url"] as? String ?? 
                                         "https://www.youtube.com/watch?v=\(videoId)"
                                
                                let videoInfo = VideoInfo(
                                    title: title,
                                    uploader: entry["uploader"] as? String ?? entry["channel"] as? String,
                                    duration: entry["duration"] as? Double,
                                    webpage_url: url,
                                    thumbnail: entry["thumbnail"] as? String ?? (entry["thumbnails"] as? [[String: Any]])?.first?["url"] as? String,
                                    formats: nil,
                                    description: entry["description"] as? String,
                                    upload_date: entry["upload_date"] as? String,
                                    timestamp: entry["timestamp"] as? Double,
                                    view_count: entry["view_count"] as? Int,
                                    like_count: entry["like_count"] as? Int,
                                    channel_id: entry["channel_id"] as? String,
                                    uploader_id: entry["uploader_id"] as? String,
                                    uploader_url: entry["uploader_url"] as? String
                                )
                                videos.append(videoInfo)
                            }
                        }
                    }
                }
            } catch {
                DebugLogger.shared.log("Failed to parse playlist JSON: \(error)", level: .error)
                throw error
            }
        }
        
        return PlaylistConfirmationView.PlaylistInfo(
            title: playlistTitle,
            uploader: playlistUploader,
            videoCount: videos.count,
            videos: videos,
            playlistId: playlistId
        )
    }
    
    func fetchMetadata(for urlString: String) async throws -> VideoInfo {
        let ytdlpPath = try getYTDLPPath()  // Consistent approach
        
        DebugLogger.shared.log("Fetching metadata for: \(urlString)", level: .info)
        DebugLogger.shared.log("Using yt-dlp at: \(ytdlpPath)", level: .info)
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        
        // Register with ProcessManager
        await ProcessManager.shared.register(process)
        
        // These arguments tell yt-dlp what we want:
        // --dump-json: Give us metadata as JSON instead of downloading
        // --no-playlist: Just this video, not the whole playlist
        // --no-warnings: Suppress warnings that might interfere with JSON
        process.arguments = [
            "--dump-json",
            "--no-playlist",
            "--no-warnings",
            urlString
        ]
        
        let fullCommand = "\(ytdlpPath) \(process.arguments!.joined(separator: " "))"
        DebugLogger.shared.log("Fetching metadata", level: .command, details: fullCommand)
        
        // Set up pipes for both output and errors
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe  // Capture error messages too
        
        // Declare data variables outside do block
        var data = Data()
        var errorData = Data()
        
        // Run the process with timeout
        do {
            try process.run()
            
            // Create timeout for metadata fetch (30 seconds should be plenty)
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                
                if process.isRunning {
                    PersistentDebugLogger.shared.log(
                        "Metadata fetch timed out",
                        level: .error,
                        details: "URL: \(urlString)"
                    )
                    await ProcessManager.shared.terminate(process)
                }
            }
            
            // Read the output BEFORE waiting for exit to prevent deadlock with large outputs
            data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            // Wait for process to complete
            await withCheckedContinuation { continuation in
                DispatchQueue.global().async {
                    process.waitUntilExit()
                    continuation.resume()
                }
            }
            
            // Cancel timeout
            timeoutTask.cancel()
            
            // Unregister from ProcessManager
            await ProcessManager.shared.unregister(process)
        } catch {
            await ProcessManager.shared.unregister(process)
            throw error
        }
        
        // Check if yt-dlp succeeded (exit code 0 means success)
        if process.terminationStatus != 0 {
            // Something went wrong - let's see what yt-dlp said
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            
            DebugLogger.shared.log("Metadata fetch failed", level: .error, details: "Exit code: \(process.terminationStatus)\n\(errorMessage)")
            
            // Throw an error with the message
            throw YTDLPError.processFailed(errorMessage)
        }
        
        // Log the size of data received
        DebugLogger.shared.log("Received \(data.count) bytes of metadata", level: .info)
        
        // Check if we got any data
        guard !data.isEmpty else {
            DebugLogger.shared.log("No data received from yt-dlp", level: .error)
            throw YTDLPError.invalidJSON("No data received from yt-dlp")
        }
        
        // Try to convert to string first to see what we got
        if let jsonString = String(data: data, encoding: .utf8) {
            // Log first 500 characters for debugging
            let preview = String(jsonString.prefix(500))
            DebugLogger.shared.log("JSON preview", level: .info, details: "\(preview)...")
            
            // Check if it's actually JSON
            if !jsonString.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).starts(with: "{") {
                DebugLogger.shared.log("Output doesn't look like JSON", level: .error, details: jsonString)
                throw YTDLPError.invalidJSON("Output is not valid JSON format")
            }
        }
        
        // Try to decode the JSON into our VideoInfo structure
        do {
            let videoInfo = try JSONDecoder().decode(VideoInfo.self, from: data)
            
            // Success! We got the video information
            DebugLogger.shared.log("Successfully parsed: \(videoInfo.title)", level: .success)
            
            return videoInfo
        } catch {
            // JSON parsing failed - this might mean yt-dlp's output format changed
            // or the video has properties we haven't accounted for
            DebugLogger.shared.log("Failed to decode JSON", level: .error, details: error.localizedDescription)
            throw YTDLPError.invalidJSON("Failed to parse metadata: \(error.localizedDescription)")
        }
    }
    
    // New download method for queue system - MINIMAL VERSION
    func downloadVideo(url: String, format: VideoFormat?, outputPath: String, downloadTask: QueueDownloadTask) async throws {
        let ytdlpPath = try getYTDLPPath()
        
        DebugLogger.shared.log("Queue download starting", level: .info, details: "URL: \(url)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        
        // Build arguments - MINIMAL ONLY!
        var arguments: [String] = []
        
        // 0. Anti-bot detection measures
        arguments.append(contentsOf: [
            "--user-agent", "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        ])
        
        // 1. Never download playlists
        arguments.append("--no-playlist")
        
        // 2. Format selection - default to best quality with fallback
        if let format = format, !format.format_id.isEmpty {
            var formatString = format.format_id
            if format.needsAudioMerge {
                formatString = "\(format.format_id)+bestaudio/best"
            }
            arguments.append(contentsOf: ["-f", formatString])
        } else {
            // Default: best quality with automatic fallback
            arguments.append(contentsOf: ["-f", "bestvideo[ext=mp4]+bestaudio[ext=m4a]/bestvideo+bestaudio/best"])
        }
        
        // 3. Output path (simple!)
        let downloadPath = outputPath.isEmpty ? preferences.resolvedDownloadPath : outputPath
        let outputTemplate = downloadPath + "/%(title)s.%(ext)s"
        arguments.append(contentsOf: ["-o", outputTemplate])
        
        // 4. Progress tracking (minimal)
        arguments.append(contentsOf: [
            "--newline",
            "--progress",
            "--no-part"
        ])
        
        // 5. Force MP4 output
        arguments.append(contentsOf: ["--merge-output-format", "mp4"])
        
        // 6. ffmpeg location if found
        if let ffmpegPath = findFFmpeg() {
            arguments.append(contentsOf: ["--ffmpeg-location", ffmpegPath])
        }
        
        // 7. SponsorBlock (only if enabled)
        if preferences.sponsorBlockEnabled {
            arguments.append(contentsOf: [
                "--sponsorblock-mark", "all",
                "--sponsorblock-remove", "sponsor,selfpromo,interaction,music_offtopic"
            ])
        }
        
        // 8. Cookie extraction (helps with bot detection)
        if preferences.cookieSource != "none" {
            if preferences.cookieSource == "file" {
                if let cookiePath = UserDefaults.standard.string(forKey: "cookieFilePath") {
                    arguments.append(contentsOf: ["--cookies", cookiePath])
                }
            } else {
                arguments.append(contentsOf: ["--cookies-from-browser", preferences.cookieSource])
            }
        }
        
        // Add the URL last
        arguments.append(url)
        
        process.arguments = arguments
        
        // Set up environment to include common binary paths
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment
        
        // Log the full command
        let fullCommand = "\(ytdlpPath) \(arguments.joined(separator: " "))"
        DebugLogger.shared.log("Executing download", level: .command, details: fullCommand)
        
        // Set up pipes
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Read output
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let output = String(data: data, encoding: .utf8) {
                for line in output.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        if trimmed.contains("ERROR") {
                            DebugLogger.shared.log("Download error", level: .error, details: trimmed)
                            Task { @MainActor in
                                downloadTask.downloadStatus = "Error"
                                downloadTask.status = .failed
                            }
                        } else if trimmed.contains("WARNING") {
                            DebugLogger.shared.log("Download warning", level: .warning, details: trimmed)
                        } else if trimmed.contains("[download]") {
                            self.parseProgress(line: trimmed, for: downloadTask)
                        } else if trimmed.contains("[ffmpeg]") {
                            DebugLogger.shared.log("Merging", level: .info, details: trimmed)
                            Task { @MainActor in
                                downloadTask.downloadStatus = "Merging"
                            }
                        } else {
                            DebugLogger.shared.log("yt-dlp", level: .info, details: trimmed)
                        }
                    }
                }
            }
        }
        
        // Read stderr (may contain debug info, not just errors)
        errorPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }
            
            if let error = String(data: data, encoding: .utf8) {
                let trimmed = error.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    // Categorize stderr output
                    if trimmed.contains("[debug]") {
                        DebugLogger.shared.log("Debug info", level: .info, details: trimmed)
                    } else if trimmed.contains("WARNING") {
                        DebugLogger.shared.log("Warning", level: .warning, details: trimmed)
                    } else if trimmed.contains("ERROR") || trimmed.contains("error:") {
                        DebugLogger.shared.log("Error", level: .error, details: trimmed)
                    } else {
                        // Default to info for other stderr output
                        DebugLogger.shared.log("Info", level: .info, details: trimmed)
                    }
                }
            }
        }
        
        // Start the process
        do {
            try process.run()
            DebugLogger.shared.log("Download process started", level: .success)
            
            await MainActor.run {
                downloadTask.downloadStatus = "Downloading"
                downloadTask.status = .downloading
            }
        } catch {
            DebugLogger.shared.log("Failed to start download", level: .error, details: error.localizedDescription)
            throw error
        }
        
        // Wait for completion
        process.waitUntilExit()
        
        // Clean up handlers
        outputPipe.fileHandleForReading.readabilityHandler = nil
        errorPipe.fileHandleForReading.readabilityHandler = nil
        
        // Check result
        if process.terminationStatus == 0 {
            DebugLogger.shared.log("Download completed successfully", level: .success)
            await MainActor.run {
                downloadTask.progress = 1.0
                downloadTask.downloadStatus = "Completed"
                downloadTask.status = .completed
            }
        } else {
            let errorMsg = "Download failed with exit code: \(process.terminationStatus)"
            DebugLogger.shared.log(errorMsg, level: .error)
            
            // Read any remaining error output
            let finalError = errorPipe.fileHandleForReading.readDataToEndOfFile()
            if let errorStr = String(data: finalError, encoding: .utf8), !errorStr.isEmpty {
                DebugLogger.shared.log("Final error", level: .error, details: errorStr)
            }
            
            await MainActor.run {
                downloadTask.downloadStatus = "Failed"
                downloadTask.status = .failed
            }
            
            throw YTDLPError.processFailed(errorMsg)
        }
    }
    
    private func parseProgress(line output: String, for downloadTask: QueueDownloadTask) {
        Task { @MainActor in
            // Parse download percentage
            if let range = output.range(of: #"(\d+\.?\d*)%"#, options: .regularExpression) {
                let percentStr = String(output[range]).dropLast()
                if let percent = Double(percentStr) {
                    downloadTask.progress = percent / 100.0  // Convert to 0-1 range
                }
            }
            
            // Parse speed
            if let range = output.range(of: #"at\s+([\d.]+\w+/s)"#, options: .regularExpression) {
                let speedStr = String(output[range]).replacingOccurrences(of: "at ", with: "")
                downloadTask.speed = speedStr
            }
            
            // Parse ETA
            if let range = output.range(of: #"ETA\s+([\d:]+)"#, options: .regularExpression) {
                let etaStr = String(output[range]).replacingOccurrences(of: "ETA ", with: "")
                downloadTask.eta = etaStr
            }
            
            // Update status based on content
            if output.contains("[download]") && output.contains("Destination:") {
                downloadTask.downloadStatus = "Starting download"
            } else if output.contains("[ffmpeg]") {
                downloadTask.downloadStatus = "Merging"
            } else if output.contains("100%") {
                downloadTask.downloadStatus = "Finalizing"
            } else if downloadTask.progress > 0 {
                downloadTask.downloadStatus = "Downloading"
            }
        }
    }
    
    // MARK: - Version checking and upgrading
    
    func getLatestYTDLPVersion() async throws -> String {
        // Check latest version available via brew
        let brewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew"      // Intel
        ]
        
        var brewPath: String?
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                brewPath = path
                break
            }
        }
        
        guard let brew = brewPath else {
            throw YTDLPError.processFailed("Homebrew not found")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brew)
        process.arguments = ["info", "yt-dlp", "--json"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        // Parse JSON to get version
        if let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           let firstItem = json.first,
           let versions = firstItem["versions"] as? [String: Any],
           let stable = versions["stable"] as? String {
            return stable
        }
        
        // Fallback: try to parse from regular brew info
        let process2 = Process()
        process2.executableURL = URL(fileURLWithPath: brew)
        process2.arguments = ["info", "yt-dlp"]
        
        let pipe2 = Pipe()
        process2.standardOutput = pipe2
        
        try process2.run()
        process2.waitUntilExit()
        
        let data2 = pipe2.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data2, encoding: .utf8) {
            // Parse "yt-dlp: stable 2024.01.01" format
            if let range = output.range(of: "stable ") {
                let afterStable = String(output[range.upperBound...])
                if let version = afterStable.split(separator: " ").first {
                    return String(version).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return "Unknown"
    }
    
    func getLatestFFmpegVersion() async throws -> String {
        // Check latest version available via brew
        let brewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew"      // Intel
        ]
        
        var brewPath: String?
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                brewPath = path
                break
            }
        }
        
        guard let brew = brewPath else {
            throw YTDLPError.processFailed("Homebrew not found")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brew)
        process.arguments = ["info", "ffmpeg"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            // Parse "ffmpeg: stable x.x.x" format
            if let range = output.range(of: "stable ") {
                let afterStable = String(output[range.upperBound...])
                if let version = afterStable.split(separator: " ").first {
                    return String(version).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        return "Unknown"
    }
    
    func getYTDLPVersion() async throws -> String {
        guard let ytdlpPath = findYTDLP() else {
            throw YTDLPError.ytdlpNotFound
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        process.arguments = ["--version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let version = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw YTDLPError.processFailed("Failed to get version")
        }
        
        return version
    }
    
    func getFFmpegVersion() async throws -> String {
        guard let ffmpegPath = findFFmpeg() else {
            throw YTDLPError.processFailed("ffmpeg not found")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        process.arguments = ["-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8),
              let firstLine = output.split(separator: "\n").first else {
            throw YTDLPError.processFailed("Failed to get ffmpeg version")
        }
        
        // Extract version from "ffmpeg version x.x.x"
        let versionString = String(firstLine)
        if let range = versionString.range(of: "version ") {
            let afterVersion = String(versionString[range.upperBound...])
            let version = afterVersion.split(separator: " ").first ?? ""
            return String(version)
        }
        
        return "Unknown"
    }
    
    func upgradeYTDLP() async throws -> String {
        // Check if Homebrew is installed
        let brewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew"      // Intel
        ]
        
        var brewPath: String?
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                brewPath = path
                break
            }
        }
        
        guard let brew = brewPath else {
            throw YTDLPError.processFailed("Homebrew not found. Please install from https://brew.sh")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brew)
        process.arguments = ["upgrade", "yt-dlp"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if process.terminationStatus != 0 {
            let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw YTDLPError.processFailed("Upgrade failed: \(error)")
        }
        
        let output = String(data: outputData, encoding: .utf8) ?? ""
        
        // Get new version
        let newVersion = try await getYTDLPVersion()
        return newVersion
    }
    
    func upgradeFFmpeg() async throws -> String {
        // Check if Homebrew is installed
        let brewPaths = [
            "/opt/homebrew/bin/brew",  // Apple Silicon
            "/usr/local/bin/brew"      // Intel
        ]
        
        var brewPath: String?
        for path in brewPaths {
            if FileManager.default.fileExists(atPath: path) {
                brewPath = path
                break
            }
        }
        
        guard let brew = brewPath else {
            throw YTDLPError.processFailed("Homebrew not found. Please install from https://brew.sh")
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brew)
        process.arguments = ["upgrade", "ffmpeg"]
        
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        try process.run()
        process.waitUntilExit()
        
        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw YTDLPError.processFailed("Upgrade failed: \(error)")
        }
        
        // Get new version
        let newVersion = try await getFFmpegVersion()
        return newVersion
    }
}

// Enum for different errors that can occur
enum YTDLPError: LocalizedError {
    case ytdlpNotFound
    case invalidJSON(String)
    case processFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .ytdlpNotFound:
            return "yt-dlp is not installed. Please install it using: brew install yt-dlp"
        case .invalidJSON(let details):
            return "Failed to parse video information: \(details)"
        case .processFailed(let details):
            return "yt-dlp process failed: \(details)"
        }
    }
}
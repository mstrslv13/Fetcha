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
            await ProcessManager.shared.unregister(process)
            
            // Clean up
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            process.cleanupPipes()
            
            throw error
        }
        
        // Clean up after process completes
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
        var arguments = [
            "--dump-single-json",
            "--flat-playlist"
        ]
        
        // Add cookie support
        switch preferences.cookieSource {
        case "safari":
            arguments.append(contentsOf: ["--cookies-from-browser", "safari"])
        case "chrome":
            arguments.append(contentsOf: ["--cookies-from-browser", "chrome"])
        case "brave":
            arguments.append(contentsOf: ["--cookies-from-browser", "brave"])
        case "firefox":
            arguments.append(contentsOf: ["--cookies-from-browser", "firefox:*.youtube.com,*.googlevideo.com"])
        case "edge":
            arguments.append(contentsOf: ["--cookies-from-browser", "edge"])
        case "file":
            if let cookiePath = UserDefaults.standard.string(forKey: "cookieFilePath"),
               let validatedPath = InputValidator.validateCookiePath(cookiePath) {
                arguments.append(contentsOf: ["--cookies", validatedPath])
            } else {
                DebugLogger.shared.log("Cookie file validation failed", level: .warning)
            }
        default:
            break
        }
        
        arguments.append(urlString)
        process.arguments = arguments
        
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
            "--flat-playlist"
        ]
        
        // Add playlist range if specified
        if let limit = limit {
            args.insert(contentsOf: ["--playlist-items", "1-\(limit)"], at: 0)
        }
        
        // Add cookie support
        switch preferences.cookieSource {
        case "safari":
            args.append(contentsOf: ["--cookies-from-browser", "safari"])
        case "chrome":
            args.append(contentsOf: ["--cookies-from-browser", "chrome"])
        case "brave":
            args.append(contentsOf: ["--cookies-from-browser", "brave"])
        case "firefox":
            args.append(contentsOf: ["--cookies-from-browser", "firefox:*.youtube.com,*.googlevideo.com"])
        case "edge":
            args.append(contentsOf: ["--cookies-from-browser", "edge"])
        case "file":
            if let cookiePath = UserDefaults.standard.string(forKey: "cookieFilePath"),
               let validatedPath = InputValidator.validateCookiePath(cookiePath) {
                args.append(contentsOf: ["--cookies", validatedPath])
            }
        default:
            break
        }
        
        args.append(urlString)
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
        var arguments = [
            "--dump-json",
            "--no-playlist",
            "--no-warnings"
        ]
        
        // Add cookie support for getting high quality formats
        switch preferences.cookieSource {
        case "safari":
            arguments.append(contentsOf: ["--cookies-from-browser", "safari"])
        case "chrome":
            arguments.append(contentsOf: ["--cookies-from-browser", "chrome"])
        case "brave":
            arguments.append(contentsOf: ["--cookies-from-browser", "brave"])
        case "firefox":
            arguments.append(contentsOf: ["--cookies-from-browser", "firefox:*.youtube.com,*.googlevideo.com"])
        case "edge":
            arguments.append(contentsOf: ["--cookies-from-browser", "edge"])
        case "file":
            if let cookiePath = UserDefaults.standard.string(forKey: "cookieFilePath"),
               let validatedPath = InputValidator.validateCookiePath(cookiePath) {
                arguments.append(contentsOf: ["--cookies", validatedPath])
            } else {
                DebugLogger.shared.log("Cookie file validation failed", level: .warning)
            }
        default:
            break // No cookies
        }
        
        // Validate and add the URL at the end
        let sanitizedURL = sanitizeURL(urlString)
        guard !sanitizedURL.isEmpty else {
            throw YTDLPError.processFailed("Invalid URL provided")
        }
        arguments.append(sanitizedURL)
        
        process.arguments = arguments
        
        // Create safe command string for logging (escape special characters)
        let safeArgs: [String] = process.arguments?.map { arg in
            // Escape shell special characters for safe logging
            if arg.contains(" ") || arg.contains("'") || arg.contains("\"") || 
               arg.contains(";") || arg.contains("&") || arg.contains("|") || 
               arg.contains("$") || arg.contains("`") {
                return "'\(arg.replacingOccurrences(of: "'", with: "'\\'\''"))'"
            } else {
                return arg
            }
        } ?? []
        let fullCommand = "\(ytdlpPath) \(safeArgs.joined(separator: " "))"
        DebugLogger.shared.log("Fetching metadata", level: .command, details: fullCommand)
        
        // Set up pipes for both output and errors
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe  // Capture error messages too
        
        // Variables for output data
        let data: Data
        let errorData: Data
        
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
            if !jsonString.trimmingCharacters(in: .whitespacesAndNewlines).starts(with: "{") {
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
    
    // New download method for queue system - FIXED VERSION
    func downloadVideo(url: String, format: VideoFormat?, outputPath: String, downloadTask: QueueDownloadTask) async throws {
        let ytdlpPath = try getYTDLPPath()
        
        DebugLogger.shared.log("Queue download starting", level: .info, details: "URL: \(url)")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlpPath)
        
        // Build arguments properly
        var arguments: [String] = []
        
        // CRITICAL: Never download playlists, only single videos
        arguments.append("--no-playlist")
        
        // Handle audio-only downloads
        if preferences.downloadAudio {
            arguments.append("-x")  // Extract audio
            arguments.append("--audio-format")
            arguments.append(preferences.audioFormat)
            DebugLogger.shared.log("Audio-only mode", level: .info, details: "Format: \(preferences.audioFormat)")
        } else {
            // Add format selection if specified
            if let format = format {
                var formatArg = format.format_id
                
                // Check if we need to merge audio
                if format.needsAudioMerge {
                    formatArg = "\(format.format_id)+bestaudio/\(format.format_id)+bestaudio[ext=mp4]/best"
                    DebugLogger.shared.log("Format needs audio merge", level: .info, details: formatArg)
                }
            
                arguments.append(contentsOf: ["-f", formatArg])
            } else if preferences.defaultVideoQuality != "best" {
                // Use user's preferred quality
                let quality = preferences.defaultVideoQuality
                let formatString = "bestvideo[height<=\(quality.replacingOccurrences(of: "p", with: ""))]+bestaudio/best[height<=\(quality.replacingOccurrences(of: "p", with: ""))]"
                arguments.append(contentsOf: ["-f", formatString])
            } else {
                // Use best quality by default
                arguments.append(contentsOf: ["-f", "bestvideo+bestaudio/best"])
            }
        }
        
        // Set output path - outputPath should already be correctly determined by DownloadQueue
        // based on format type and user preferences (separate locations for audio/video)
        let downloadPath = outputPath.isEmpty ? preferences.resolvedDownloadPath : outputPath
        DebugLogger.shared.log("Download path", level: .info, details: "Using path: \(downloadPath)")
        
        var outputTemplate = downloadPath
        
        // Add subfolder if enabled
        if preferences.createSubfolders && !preferences.subfolderTemplate.isEmpty {
            outputTemplate += "/\(preferences.subfolderTemplate)"
        }
        
        // Add naming template
        outputTemplate += "/\(preferences.namingTemplate)"
        
        DebugLogger.shared.log("Output template", level: .info, details: outputTemplate)
        arguments.append(contentsOf: ["-o", outputTemplate])
        
        // Apply filename sanitization options
        if preferences.removeSpecialCharacters {
            arguments.append("--restrict-filenames")
            PersistentDebugLogger.shared.log("Using restricted filenames (remove special characters)", level: .info)
        }
        
        if preferences.replaceSpacesWithUnderscores {
            // This is handled by --restrict-filenames when enabled
            // or we can use --replace-in-metadata but that's for metadata not filenames
            // For now, this will be handled by --restrict-filenames which also replaces spaces
            if !preferences.removeSpecialCharacters {
                arguments.append("--restrict-filenames")
                PersistentDebugLogger.shared.log("Replacing spaces with underscores", level: .info)
            }
        }
        
        if preferences.limitFilenameLength {
            // yt-dlp automatically limits filenames to filesystem limits
            // We can add --trim-filenames to enforce a specific limit
            arguments.append(contentsOf: ["--trim-filenames", "200"])
            PersistentDebugLogger.shared.log("Limiting filename length to 200 characters", level: .info)
        }
        
        // Add progress and debugging output
        arguments.append(contentsOf: [
            "--newline",
            "--progress",
            "--verbose",
            "--no-part",
            "--no-mtime"  // Don't set file modification time (can cause issues)
        ])
        
        // Explicitly set ffmpeg location if found
        if let ffmpegPath = findFFmpeg() {
            arguments.append(contentsOf: ["--ffmpeg-location", ffmpegPath])
        } else {
            DebugLogger.shared.log("Warning: ffmpeg not found, video/audio merging may fail", level: .warning)
        }
        
        // Only set merge format for video downloads
        if !preferences.downloadAudio {
            arguments.append(contentsOf: ["--merge-output-format", "mp4"])
        }
        
        // Add rate limit if set
        if preferences.rateLimitKbps > 0 {
            arguments.append(contentsOf: ["-r", "\(preferences.rateLimitKbps)K"])
        }
        
        // Add retry attempts
        if preferences.retryAttempts > 0 {
            arguments.append(contentsOf: ["--retries", "\(preferences.retryAttempts)"])
        }
        
        // Keep original files if requested
        if preferences.keepOriginalFiles {
            arguments.append("-k")
        }
        
        // Handle thumbnails
        if preferences.embedThumbnail {
            // Embed thumbnail in the video file
            arguments.append("--embed-thumbnail")
            // Also write thumbnail separately for history
            arguments.append("--write-thumbnail")
        } else {
            // Still write thumbnail separately for display in history/queue
            arguments.append("--write-thumbnail")
        }
        
        // Add metadata
        arguments.append("--add-metadata")
        
        // Embed subtitles if requested
        if preferences.embedSubtitles {
            arguments.append("--embed-subs")
            arguments.append(contentsOf: ["--sub-langs", preferences.subtitleLanguages])
        }
        
        // Handle cookies if configured
        // Note: Browsers need to be closed for cookie extraction to work
        // We'll try to extract cookies but continue without them if it fails
        switch preferences.cookieSource {
        case "safari":
            arguments.append(contentsOf: ["--cookies-from-browser", "safari"])
            PersistentDebugLogger.shared.log("Using Safari cookies", level: .info)
            DebugLogger.shared.log("Using Safari cookies", level: .info)
        case "chrome":
            arguments.append(contentsOf: ["--cookies-from-browser", "chrome"])
            PersistentDebugLogger.shared.log("Using Chrome cookies", level: .info)
            DebugLogger.shared.log("Using Chrome cookies", level: .info)
        case "brave":
            arguments.append(contentsOf: ["--cookies-from-browser", "brave"])
            PersistentDebugLogger.shared.log("Using Brave cookies", level: .info)
            DebugLogger.shared.log("Using Brave cookies", level: .info)
        case "firefox":
            // Firefox often has many cookies which can cause HTTP 413 errors
            // Add domain filtering to reduce cookie count
            arguments.append(contentsOf: ["--cookies-from-browser", "firefox:*.youtube.com,*.googlevideo.com"])
            PersistentDebugLogger.shared.log("Using Firefox cookies (filtered for YouTube domains)", level: .info)
            DebugLogger.shared.log("Using Firefox cookies (filtered for YouTube domains)", level: .info)
        case "edge":
            arguments.append(contentsOf: ["--cookies-from-browser", "edge"])
            PersistentDebugLogger.shared.log("Using Edge cookies", level: .info)
            DebugLogger.shared.log("Using Edge cookies", level: .info)
        case "file":
            if let cookiePath = UserDefaults.standard.string(forKey: "cookieFilePath"),
               let validatedPath = InputValidator.validateCookiePath(cookiePath) {
                arguments.append(contentsOf: ["--cookies", validatedPath])
                PersistentDebugLogger.shared.log("Using cookie file: \(validatedPath)", level: .info)
                DebugLogger.shared.log("Using cookie file: \(validatedPath)", level: .info)
            } else {
                PersistentDebugLogger.shared.log("Cookie file validation failed", level: .warning)
                DebugLogger.shared.log("Cookie file validation failed", level: .warning)
            }
        case "none":
            break // No cookies
        default:
            PersistentDebugLogger.shared.log("Unknown cookie source: \(preferences.cookieSource)", level: .warning)
            DebugLogger.shared.log("Unknown cookie source: \(preferences.cookieSource)", level: .warning)
        }
        
        // Validate and add the URL last
        let sanitizedURL = sanitizeURL(url)
        guard !sanitizedURL.isEmpty else {
            Task {
                await MainActor.run {
                    downloadTask.errorMessage = "Invalid URL provided"
                    downloadTask.status = .failed
                }
            }
            throw YTDLPError.processFailed("Invalid URL provided")
        }
        arguments.append(sanitizedURL)
        
        process.arguments = arguments
        
        // Log the full command being executed (with proper escaping)
        let safeArgs: [String] = arguments.map { arg in
            if arg.contains(" ") || arg.contains("'") || arg.contains("\"") || 
               arg.contains(";") || arg.contains("&") || arg.contains("|") || 
               arg.contains("$") || arg.contains("`") {
                return "'\(arg.replacingOccurrences(of: "'", with: "'\\'\''"))'"
            } else {
                return arg
            }
        }
        let fullCommand = "\(ytdlpPath) \(safeArgs.joined(separator: " "))"
        DebugLogger.shared.log("Executing yt-dlp command", level: .command, details: fullCommand)
        
        // Set up environment to include common binary paths
        var environment = ProcessInfo.processInfo.environment
        environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = environment
        
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
                        // Log ALL yt-dlp output to debug console
                        DebugLogger.shared.log("yt-dlp", level: .command, details: trimmed)
                        
                        // Capture the destination file path
                        if trimmed.contains("[download] Destination:") {
                            if let range = trimmed.range(of: "Destination: ") {
                                let filePath = String(trimmed[range.upperBound...])
                                Task { @MainActor in
                                    downloadTask.actualFilePath = URL(fileURLWithPath: filePath)
                                }
                                DebugLogger.shared.log("Captured file path", level: .info, details: filePath)
                            }
                        } else if trimmed.contains("[Merger] Merging formats into") {
                            // Also capture merged file path
                            if let range = trimmed.range(of: "into \"") {
                                let afterInto = String(trimmed[range.upperBound...])
                                if let endRange = afterInto.range(of: "\"") {
                                    let filePath = String(afterInto[..<endRange.lowerBound])
                                    Task { @MainActor in
                                        downloadTask.actualFilePath = URL(fileURLWithPath: filePath)
                                    }
                                    DebugLogger.shared.log("Captured merged file path", level: .info, details: filePath)
                                }
                            }
                        }
                        
                        // Also handle specific cases
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
                        } else if trimmed.contains("[ffmpeg]") || trimmed.contains("[Merger]") {
                            DebugLogger.shared.log("FFmpeg processing", level: .info, details: trimmed)
                            Task { @MainActor in
                                downloadTask.downloadStatus = "Merging"
                            }
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
                for line in error.components(separatedBy: .newlines) {
                    let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmed.isEmpty {
                        // Log ALL stderr output (including ffmpeg output)
                        if trimmed.contains("ffmpeg") || trimmed.contains("frame=") || trimmed.contains("size=") {
                            // FFmpeg progress output
                            DebugLogger.shared.log("ffmpeg", level: .command, details: trimmed)
                        } else if trimmed.contains("[debug]") {
                            DebugLogger.shared.log("Debug", level: .info, details: trimmed)
                        } else if trimmed.contains("WARNING") {
                            DebugLogger.shared.log("Warning", level: .warning, details: trimmed)
                        } else if trimmed.contains("ERROR") || trimmed.contains("error:") {
                            DebugLogger.shared.log("Error", level: .error, details: trimmed)
                            
                            // Check for format not available error
                            if trimmed.contains("Requested format is not available") || 
                               trimmed.contains("requested format not available") {
                                Task { @MainActor in
                                    downloadTask.errorMessage = "Format not available - selecting alternative"
                                    // Trigger format fallback
                                    await self.handleFormatError(for: downloadTask, url: url, outputPath: outputPath)
                                }
                            }
                        } else {
                            // Default to command level for visibility
                            DebugLogger.shared.log("Process", level: .command, details: trimmed)
                        }
                    }
                }
            }
        }
        
        // Store the process reference so it can be cancelled
        await MainActor.run {
            if let task = downloadTask.downloadTask {
                task.process = process
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
            
            // If actualFilePath wasn't captured from output, try to find the downloaded file
            if downloadTask.actualFilePath == nil {
                let outputDir = URL(fileURLWithPath: outputPath)
                let videoTitle = downloadTask.title
                
                DebugLogger.shared.log("Searching for downloaded file", level: .info, details: "Title: \(videoTitle), Dir: \(outputPath)")
                
                // Try to find the downloaded file in the output directory
                if let contents = try? FileManager.default.contentsOfDirectory(at: outputDir, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) {
                    // Sort by creation date to get the most recent file
                    let sortedFiles = contents.filter { !$0.hasDirectoryPath }.sorted { url1, url2 in
                        let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                        let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                        return date1 > date2
                    }
                    
                    // First try to find a file that contains parts of the video title
                    var downloadedFile: URL? = nil
                    
                    // Clean the title for matching
                    let cleanTitle = videoTitle
                        .replacingOccurrences(of: "[", with: "")
                        .replacingOccurrences(of: "]", with: "")
                        .replacingOccurrences(of: "(", with: "")
                        .replacingOccurrences(of: ")", with: "")
                        .replacingOccurrences(of: "#", with: "")
                    
                    // Try to find by title parts
                    let titleWords = cleanTitle.split(separator: " ").prefix(3).map(String.init)
                    downloadedFile = sortedFiles.first { url in
                        let filename = url.lastPathComponent.lowercased()
                        return !filename.contains(".part") && 
                               titleWords.contains { word in filename.contains(word.lowercased()) }
                    }
                    
                    // If not found, get the most recent video file
                    if downloadedFile == nil {
                        downloadedFile = sortedFiles.first { url in
                            let ext = url.pathExtension.lowercased()
                            return ["mp4", "webm", "mkv", "avi", "mov", "flv", "mp3", "m4a", "opus", "wav", "aac"].contains(ext)
                        }
                    }
                    
                    if let foundFile = downloadedFile {
                        await MainActor.run {
                            downloadTask.actualFilePath = foundFile
                        }
                        DebugLogger.shared.log("Found downloaded file", level: .info, details: foundFile.path)
                    } else {
                        DebugLogger.shared.log("Could not find downloaded file", level: .warning, details: "Searched in: \(outputPath)")
                    }
                }
            }
            
            // Apply post-processing if enabled
            if AppPreferences.shared.enablePostProcessing, 
               let filePath = downloadTask.actualFilePath {
                await postProcessFile(filePath, downloadTask: downloadTask)
            }
            
            // Extract audio if enabled (after post-processing if that was enabled)
            if AppPreferences.shared.enableAudioExtraction {
                // Use the post-processed file if available, otherwise the original
                if let actualFile = downloadTask.actualFilePath {
                    extractAudio(from: actualFile, for: downloadTask)
                } else {
                    DebugLogger.shared.log("Cannot extract audio - file path not found", level: .warning)
                }
                
                // Wait a moment for extraction to complete
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
            
            // Try to find and save thumbnail for history
            if let actualFile = downloadTask.actualFilePath {
                let thumbnailPath = findThumbnailFile(for: actualFile)
                if let thumbnail = thumbnailPath {
                    // Save thumbnail path or convert to base64 for storage
                    await MainActor.run {
                        // Store local thumbnail path instead of URL for reliability
                        downloadTask.videoInfo.thumbnail = thumbnail.path
                    }
                    DebugLogger.shared.log("Found thumbnail file", level: .info, details: thumbnail.lastPathComponent)
                }
            }
            
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
    
    // Handle format not available error by finding alternative format
    private func handleFormatError(for downloadTask: QueueDownloadTask, url: String, outputPath: String) async {
        DebugLogger.shared.log("Handling format error", level: .warning, details: "Fetching available formats")
        
        do {
            // Fetch available formats for this video
            let info = try await fetchMetadata(for: url)
            
            guard let formats = info.formats, !formats.isEmpty else {
                await MainActor.run {
                    downloadTask.errorMessage = "No formats available"
                    downloadTask.status = .failed
                }
                return
            }
            
            // Check if we should use manual selection
            if preferences.preferManualFormatSelection && preferences.autoSelectFallbackFormat {
                // Mark for manual selection - the UI will handle showing the dialog
                await MainActor.run {
                    downloadTask.errorMessage = "Format not available - please select manually"
                    downloadTask.status = .failed
                    // Store formats for later selection
                    downloadTask.videoInfo.formats = formats
                }
                return
            }
            
            // Try to find a suitable alternative format automatically
            var alternativeFormat: VideoFormat?
            
            if preferences.autoSelectFallbackFormat {
                if let originalFormat = downloadTask.format {
                    // Try to find similar format
                    alternativeFormat = findAlternativeFormat(
                        original: originalFormat,
                        available: formats,
                        preferAudio: preferences.downloadAudio
                    )
                }
                
                // If no alternative based on original, use best available
                if alternativeFormat == nil {
                    if preferences.downloadAudio {
                        // Get best audio format
                        alternativeFormat = formats.filter { 
                            $0.acodec != nil && $0.acodec != "none" && 
                            ($0.vcodec == nil || $0.vcodec == "none")
                        }.sorted { ($0.abr ?? 0) > ($1.abr ?? 0) }.first
                    } else {
                        // Get best video format with respect to quality limits
                        let maxHeight = preferences.fallbackToLowerQuality ? preferences.maxFallbackQuality : 9999
                        alternativeFormat = formats.filter { 
                            $0.vcodec != nil && $0.vcodec != "none" &&
                            ($0.height ?? 0) <= maxHeight
                        }.sorted { ($0.height ?? 0) > ($1.height ?? 0) }.first
                    }
                }
            }
            
            if let format = alternativeFormat {
                await MainActor.run {
                    downloadTask.format = format
                    downloadTask.errorMessage = "Using alternative format: \(format.qualityLabel)"
                    downloadTask.status = .waiting
                    
                    DebugLogger.shared.log(
                        "Format fallback", 
                        level: .info, 
                        details: "Selected alternative: \(format.format_id) - \(format.qualityLabel)"
                    )
                    
                    PersistentDebugLogger.shared.log(
                        "Automatic format fallback",
                        level: .info,
                        details: "Original format unavailable, using: \(format.qualityLabel)"
                    )
                }
                
                // Retry download with new format
                // Note: This will be handled by the queue retry mechanism
            } else {
                await MainActor.run {
                    downloadTask.errorMessage = "No suitable format found - manual selection required"
                    downloadTask.status = .failed
                }
            }
        } catch {
            DebugLogger.shared.log("Failed to fetch formats", level: .error, details: error.localizedDescription)
            await MainActor.run {
                downloadTask.errorMessage = "Failed to fetch alternative formats"
                downloadTask.status = .failed
            }
        }
    }
    
    // Find alternative format similar to original
    private func findAlternativeFormat(original: VideoFormat, available: [VideoFormat], preferAudio: Bool) -> VideoFormat? {
        if preferAudio || (original.vcodec == nil || original.vcodec == "none") {
            // Audio format - find similar quality
            let targetBitrate = original.abr ?? 128
            return available
                .filter { 
                    $0.acodec != nil && $0.acodec != "none" && 
                    ($0.vcodec == nil || $0.vcodec == "none")
                }
                .min { format1, format2 in
                    let diff1 = abs((format1.abr ?? 0) - targetBitrate)
                    let diff2 = abs((format2.abr ?? 0) - targetBitrate)
                    return diff1 < diff2
                }
        } else {
            // Video format - find similar resolution
            let targetHeight = original.height ?? 720
            return available
                .filter { $0.vcodec != nil && $0.vcodec != "none" }
                .min { format1, format2 in
                    let diff1 = abs((format1.height ?? 0) - targetHeight)
                    let diff2 = abs((format2.height ?? 0) - targetHeight)
                    return diff1 < diff2
                }
        }
    }
    
    // Post-process downloaded file with ffmpeg
    private func postProcessFile(_ filePath: URL, downloadTask: QueueDownloadTask) async {
        let preferences = AppPreferences.shared
        let targetContainer = preferences.preferredContainer
        
        // Check if file already has the target extension
        if filePath.pathExtension.lowercased() == targetContainer.lowercased() {
            DebugLogger.shared.log("File already in target format", level: .info, details: targetContainer)
            return
        }
        
        // Update status
        await MainActor.run {
            downloadTask.downloadStatus = "Converting to \(targetContainer.uppercased())..."
        }
        
        // Generate output filename
        let outputPath = filePath.deletingPathExtension().appendingPathExtension(targetContainer)
        
        DebugLogger.shared.log(
            "Post-processing file", 
            level: .info, 
            details: "Converting to \(targetContainer): \(filePath.lastPathComponent)"
        )
        
        // Run ffmpeg conversion
        let process = Process()
        process.executableURL = URL(fileURLWithPath: preferences.resolvedFfmpegPath)
        
        var args = ["-i", filePath.path]
        
        // Add format-specific options
        switch targetContainer {
        case "mp4":
            // Use H.264 for maximum compatibility
            args.append(contentsOf: ["-c:v", "libx264", "-c:a", "aac"])
            args.append(contentsOf: ["-preset", "fast"])
            args.append(contentsOf: ["-movflags", "+faststart"])  // Optimize for streaming
        case "mkv":
            // Copy streams without re-encoding to preserve quality
            args.append(contentsOf: ["-c", "copy"])
        case "mov":
            // Use Apple-compatible codecs
            args.append(contentsOf: ["-c:v", "libx264", "-c:a", "aac"])
            args.append(contentsOf: ["-movflags", "+faststart"])
        case "webm":
            // Use VP9 and Opus for web
            args.append(contentsOf: ["-c:v", "libvpx-vp9", "-c:a", "libopus"])
            args.append(contentsOf: ["-b:v", "0", "-crf", "30"])  // Good quality/size balance
        case "avi":
            // Legacy format
            args.append(contentsOf: ["-c:v", "libxvid", "-c:a", "mp3"])
        case "flv":
            // Flash video
            args.append(contentsOf: ["-c:v", "libx264", "-c:a", "aac"])
        default:
            // Default: copy streams
            args.append(contentsOf: ["-c", "copy"])
        }
        
        // Overwrite output if it exists
        args.append(contentsOf: ["-y", outputPath.path])
        
        process.arguments = args
        
        // Capture output for debugging
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                DebugLogger.shared.log(
                    "Post-processing completed", 
                    level: .success, 
                    details: "Output: \(outputPath.lastPathComponent)"
                )
                
                // Update file path to the new file
                await MainActor.run {
                    downloadTask.actualFilePath = outputPath
                }
                
                // Remove original if preference is set
                if !preferences.keepOriginalAfterProcessing {
                    do {
                        try FileManager.default.removeItem(at: filePath)
                        DebugLogger.shared.log("Original file removed", level: .info)
                    } catch {
                        DebugLogger.shared.log(
                            "Failed to remove original", 
                            level: .warning, 
                            details: error.localizedDescription
                        )
                    }
                }
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                
                DebugLogger.shared.log(
                    "Post-processing failed", 
                    level: .error, 
                    details: errorOutput
                )
                
                // Keep original file on failure
                await MainActor.run {
                    downloadTask.downloadStatus = "Conversion failed - keeping original"
                }
            }
        } catch {
            DebugLogger.shared.log(
                "Failed to start ffmpeg", 
                level: .error, 
                details: error.localizedDescription
            )
            
            await MainActor.run {
                downloadTask.downloadStatus = "Post-processing unavailable"
            }
        }
    }
    
    // Find thumbnail file for a downloaded video
    private func findThumbnailFile(for videoFile: URL) -> URL? {
        let directory = videoFile.deletingLastPathComponent()
        let baseName = videoFile.deletingPathExtension().lastPathComponent
        
        // Common thumbnail extensions
        let thumbnailExtensions = ["jpg", "jpeg", "png", "webp"]
        
        for ext in thumbnailExtensions {
            let thumbnailPath = directory.appendingPathComponent("\(baseName).\(ext)")
            if FileManager.default.fileExists(atPath: thumbnailPath.path) {
                return thumbnailPath
            }
        }
        
        // Also check for .thumbnail suffix (some yt-dlp versions)
        for ext in thumbnailExtensions {
            let thumbnailPath = directory.appendingPathComponent("\(baseName).thumbnail.\(ext)")
            if FileManager.default.fileExists(atPath: thumbnailPath.path) {
                return thumbnailPath
            }
        }
        
        return nil
    }
    
    // Audio extraction using ffmpeg
    func extractAudio(from filePath: URL, for downloadTask: QueueDownloadTask) {
        guard preferences.enableAudioExtraction else { return }
        
        let ffmpegPath = preferences.resolvedFfmpegPath
        guard FileManager.default.fileExists(atPath: ffmpegPath) else {
            DebugLogger.shared.log("ffmpeg not found for audio extraction", level: .warning)
            return
        }
        
        Task {
            await MainActor.run {
                downloadTask.downloadStatus = "Extracting audio..."
            }
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: ffmpegPath)
        
        // Build output filename with audio extension
        let outputFilename = filePath.deletingPathExtension().lastPathComponent + "." + preferences.audioExtractionFormat
        let outputPath = filePath.deletingLastPathComponent().appendingPathComponent(outputFilename)
        
        var args = ["-i", filePath.path]
        
        // Configure audio extraction based on format
        switch preferences.audioExtractionFormat {
        case "mp3":
            args.append(contentsOf: ["-codec:a", "libmp3lame", "-b:a", preferences.audioExtractionBitrate])
        case "m4a":
            args.append(contentsOf: ["-codec:a", "aac", "-b:a", preferences.audioExtractionBitrate])
        case "wav":
            args.append(contentsOf: ["-codec:a", "pcm_s16le"])
        case "flac":
            args.append(contentsOf: ["-codec:a", "flac"])
        case "ogg":
            args.append(contentsOf: ["-codec:a", "libvorbis", "-b:a", preferences.audioExtractionBitrate])
        case "opus":
            args.append(contentsOf: ["-codec:a", "libopus", "-b:a", preferences.audioExtractionBitrate])
        default:
            args.append(contentsOf: ["-codec:a", "copy"])
        }
        
        // Remove video stream
        args.append(contentsOf: ["-vn"])
        
        // Overwrite output if exists
        args.append(contentsOf: ["-y", outputPath.path])
        
        process.arguments = args
        
        // Capture output
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                DebugLogger.shared.log(
                    "Audio extraction completed", 
                    level: .success, 
                    details: "Audio file: \(outputPath.lastPathComponent)"
                )
                
                Task {
                    await MainActor.run {
                        downloadTask.downloadStatus = "Audio extracted successfully"
                        // Store the audio file path for reference
                        downloadTask.extractedAudioPath = outputPath
                    }
                }
                
                // Remove video file if preference is set
                if !preferences.keepVideoAfterExtraction {
                    do {
                        try FileManager.default.removeItem(at: filePath)
                        DebugLogger.shared.log("Video file removed after extraction", level: .info)
                        
                        // Update the actual file path to point to the audio file
                        Task {
                            await MainActor.run {
                                downloadTask.actualFilePath = outputPath
                            }
                        }
                    } catch {
                        DebugLogger.shared.log(
                            "Failed to remove video file", 
                            level: .warning, 
                            details: error.localizedDescription
                        )
                    }
                }
            } else {
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                
                DebugLogger.shared.log(
                    "Audio extraction failed", 
                    level: .error, 
                    details: errorOutput
                )
                
                Task {
                    await MainActor.run {
                        downloadTask.downloadStatus = "Audio extraction failed"
                    }
                }
            }
        } catch {
            DebugLogger.shared.log(
                "Failed to start audio extraction", 
                level: .error, 
                details: error.localizedDescription
            )
            
            Task {
                await MainActor.run {
                    downloadTask.downloadStatus = "Audio extraction unavailable"
                }
            }
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
    
    // MARK: - Security Helper Methods
    
    /// Sanitize file paths to prevent path traversal attacks
    private func sanitizeFilePath(_ path: String) -> String {
        // Use InputValidator for proper validation
        guard let validatedPath = InputValidator.validatePath(path) else {
            DebugLogger.shared.log("Invalid path rejected: \(path)", level: .warning)
            return ""
        }
        return validatedPath
    }
    
    /// Validate and sanitize URLs to prevent injection attacks
    private func sanitizeURL(_ urlString: String) -> String {
        // Use InputValidator for proper URL validation
        guard let validatedURL = InputValidator.validateURL(urlString) else {
            DebugLogger.shared.log("Invalid URL rejected: \(urlString)", level: .warning)
            return ""
        }
        return validatedURL
    }
    
    /// Sanitize filename to prevent directory traversal and command injection
    private func sanitizeFilename(_ filename: String) -> String {
        // Use InputValidator for proper filename sanitization
        return InputValidator.validateFilename(filename)
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
            return "Download tool not found. Please ensure yt-dlp is installed."
        case .invalidJSON(let _):
            return "Unable to process video information. The video may be unavailable or restricted."
        case .processFailed(let details):
            // Check for common error patterns
            if details.lowercased().contains("private") || details.lowercased().contains("unavailable") {
                return "This video is private or unavailable."
            } else if details.lowercased().contains("age") || details.lowercased().contains("sign in") {
                return "This video requires authentication. Please check your browser cookies settings."
            } else if details.lowercased().contains("format") {
                return "The requested video format is not available."
            } else {
                return "Download failed. Please check the URL and try again."
            }
        }
    }
}

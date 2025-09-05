import Foundation

// Service to track download history and prevent duplicates
class DownloadHistory: ObservableObject {
    static let shared = DownloadHistory()
    
    @Published private(set) var history: Set<DownloadRecord> = []
    
    private let historyFile: URL
    private let maxHistorySize = 10000  // Limit history to prevent unbounded growth
    
    struct DownloadRecord: Codable, Hashable {
        let videoId: String
        let url: String
        let title: String
        let downloadPath: String  // Directory path
        let actualFilePath: String?  // Full file path including filename
        let timestamp: Date
        let fileSize: Int64?
        let duration: Double?
        let thumbnail: String?  // URL or base64 encoded thumbnail
        let uploader: String?  // Channel/uploader name
        
        // Custom initializer for backward compatibility
        init(videoId: String, url: String, title: String, downloadPath: String,
             actualFilePath: String? = nil, timestamp: Date,
             fileSize: Int64? = nil, duration: Double? = nil,
             thumbnail: String? = nil, uploader: String? = nil) {
            self.videoId = videoId
            self.url = url
            self.title = title
            self.downloadPath = downloadPath
            self.actualFilePath = actualFilePath
            self.timestamp = timestamp
            self.fileSize = fileSize
            self.duration = duration
            self.thumbnail = thumbnail
            self.uploader = uploader
        }
        
        // Custom decoder for backward compatibility
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            videoId = try container.decode(String.self, forKey: .videoId)
            url = try container.decode(String.self, forKey: .url)
            title = try container.decode(String.self, forKey: .title)
            downloadPath = try container.decode(String.self, forKey: .downloadPath)
            timestamp = try container.decode(Date.self, forKey: .timestamp)
            
            // Optional fields with defaults for backward compatibility
            actualFilePath = try container.decodeIfPresent(String.self, forKey: .actualFilePath)
            fileSize = try container.decodeIfPresent(Int64.self, forKey: .fileSize)
            duration = try container.decodeIfPresent(Double.self, forKey: .duration)
            thumbnail = try container.decodeIfPresent(String.self, forKey: .thumbnail)
            uploader = try container.decodeIfPresent(String.self, forKey: .uploader)
        }
        
        // Hash only on videoId for duplicate detection
        func hash(into hasher: inout Hasher) {
            hasher.combine(videoId)
        }
        
        static func == (lhs: DownloadRecord, rhs: DownloadRecord) -> Bool {
            lhs.videoId == rhs.videoId
        }
        
        // Computed property to get the actual file path
        var resolvedFilePath: String {
            // If we have an actual file path, use it
            if let actualPath = actualFilePath {
                return actualPath
            }
            // Otherwise return the download path (likely a directory)
            return downloadPath
        }
        
        // Get just the filename from the path
        var filename: String {
            if let actualPath = actualFilePath {
                return URL(fileURLWithPath: actualPath).lastPathComponent
            }
            return URL(fileURLWithPath: downloadPath).lastPathComponent
        }
    }
    
    private init() {
        // Store history in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                  in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("fetcha.stream", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, 
                                                withIntermediateDirectories: true)
        
        // Use different file for private mode
        if AppPreferences.shared.privateMode {
            historyFile = appFolder.appendingPathComponent("private_history.json")
        } else {
            historyFile = appFolder.appendingPathComponent("download_history.json")
        }
        
        loadHistory()
        
        // Auto-clear old history on startup
        performAutoClear()
    }
    
    // Check if a video has been downloaded before
    func hasDownloaded(videoId: String) -> Bool {
        history.contains { $0.videoId == videoId }
    }
    
    func hasDownloaded(url: String) -> Bool {
        // Extract video ID from URL if possible
        if let videoId = extractVideoId(from: url) {
            return hasDownloaded(videoId: videoId)
        }
        // Fallback to URL matching
        return history.contains { $0.url == url }
    }
    
    // Add a download to history
    func addToHistory(videoId: String, url: String, title: String, 
                      downloadPath: String, actualFilePath: String? = nil,
                      fileSize: Int64? = nil, duration: Double? = nil,
                      thumbnail: String? = nil, uploader: String? = nil) {
        // Don't save to history in private mode if configured
        if AppPreferences.shared.privateMode {
            return
        }
        
        let record = DownloadRecord(
            videoId: videoId,
            url: url,
            title: title,
            downloadPath: downloadPath,
            actualFilePath: actualFilePath,
            timestamp: Date(),
            fileSize: fileSize,
            duration: duration,
            thumbnail: thumbnail,
            uploader: uploader
        )
        
        history.insert(record)
        
        // Trim history if it gets too large
        if history.count > maxHistorySize {
            // Remove oldest records
            let sorted = history.sorted { $0.timestamp < $1.timestamp }
            let toKeep = sorted.suffix(maxHistorySize)
            history = Set(toKeep)
        }
        
        saveHistory()
    }
    
    // Get all downloads for a specific playlist
    func getPlaylistDownloads(playlistId: String) -> [DownloadRecord] {
        // Filter by playlist URL pattern
        history.filter { record in
            record.url.contains("list=\(playlistId)")
        }.sorted { $0.timestamp > $1.timestamp }
    }
    
    // Clear history with optional confirmation
    func clearHistory(skipConfirmation: Bool = false) {
        if !skipConfirmation {
            // This should be called from UI with confirmation
            // For now, we'll just clear
        }
        history.removeAll()
        saveHistory()
    }
    
    // Perform auto-clear based on preferences
    func performAutoClear() {
        let autoClearSetting = AppPreferences.shared.historyAutoClear
        guard autoClearSetting != "never" else { return }
        
        if let days = Int(autoClearSetting) {
            clearOldRecords(olderThanDays: days)
        }
    }
    
    // Clear old records (older than days specified)
    func clearOldRecords(olderThanDays: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date())!
        history = history.filter { $0.timestamp > cutoffDate }
        saveHistory()
    }
    
    // Check if file still exists at download path
    func verifyDownloadExists(_ record: DownloadRecord) -> Bool {
        // First try the actual file path if available
        if let actualPath = record.actualFilePath {
            if FileManager.default.fileExists(atPath: actualPath) {
                return true
            }
        }
        // Fall back to checking the download path
        return FileManager.default.fileExists(atPath: record.downloadPath)
    }
    
    // Remove records for deleted files
    func cleanupDeletedFiles() {
        history = history.filter { verifyDownloadExists($0) }
        saveHistory()
    }
    
    // Find the actual file for a history record
    func findActualFile(for record: DownloadRecord) -> URL? {
        // If we have an actual file path stored, use it
        if let actualPath = record.actualFilePath {
            let url = URL(fileURLWithPath: actualPath)
            if FileManager.default.fileExists(atPath: actualPath) {
                return url
            }
        }
        
        // Otherwise try to find the file in the directory
        let url = URL(fileURLWithPath: record.downloadPath)
        var isDirectory: ObjCBool = false
        
        if FileManager.default.fileExists(atPath: record.downloadPath, isDirectory: &isDirectory) {
            if !isDirectory.boolValue {
                // It's already a file
                return url
            }
            
            // It's a directory, try to find the video file
            if let contents = try? FileManager.default.contentsOfDirectory(at: url, 
                                                                          includingPropertiesForKeys: [.creationDateKey], 
                                                                          options: .skipsHiddenFiles) {
                // Clean the title for better matching
                let cleanTitle = record.title
                    .replacingOccurrences(of: "[", with: "")
                    .replacingOccurrences(of: "]", with: "")
                    .replacingOccurrences(of: "(", with: "")
                    .replacingOccurrences(of: ")", with: "")
                    .replacingOccurrences(of: "#", with: "")
                
                let titleWords = cleanTitle.split(separator: " ").prefix(3).map(String.init)
                
                // Sort by creation date and find the most recent matching file
                let sortedFiles = contents.filter { !$0.hasDirectoryPath }.sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
                
                // Look for a file containing title words
                let videoExtensions = ["mp4", "webm", "mkv", "avi", "mov", "flv", "mp3", "m4a", "opus", "wav", "aac"]
                return sortedFiles.first { url in
                    let filename = url.lastPathComponent.lowercased()
                    let ext = url.pathExtension.lowercased()
                    return videoExtensions.contains(ext) &&
                           titleWords.contains { word in filename.contains(word.lowercased()) }
                } ?? sortedFiles.first { url in
                    // Fallback to most recent media file
                    let ext = url.pathExtension.lowercased()
                    return videoExtensions.contains(ext)
                }
            }
        }
        
        return nil
    }
    
    func loadHistory() {
        // Determine which history file to load based on private mode
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                  in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("fetcha.stream", isDirectory: true)
        
        let historyPath = AppPreferences.shared.privateMode ? 
            appFolder.appendingPathComponent("private_history.json") :
            appFolder.appendingPathComponent("download_history.json")
        
        guard FileManager.default.fileExists(atPath: historyPath.path) else { 
            history = []
            return 
        }
        
        do {
            let data = try Data(contentsOf: historyPath)
            let records = try JSONDecoder().decode([DownloadRecord].self, from: data)
            history = Set(records)
        } catch {
            print("Failed to load download history: \(error)")
            history = []
        }
    }
    
    private func saveHistory() {
        // Don't save in private mode (unless it's private history)
        if AppPreferences.shared.privateMode {
            return
        }
        
        do {
            let data = try JSONEncoder().encode(Array(history))
            try data.write(to: historyFile)
        } catch {
            print("Failed to save download history: \(error)")
        }
    }
    
    // Extract video ID from various URL formats
    private func extractVideoId(from url: String) -> String? {
        // YouTube video ID patterns
        let patterns = [
            "v=([a-zA-Z0-9_-]{11})",  // Standard YouTube
            "youtu.be/([a-zA-Z0-9_-]{11})",  // Short YouTube
            "embed/([a-zA-Z0-9_-]{11})",  // Embed YouTube
            "/v/([a-zA-Z0-9_-]{11})",  // Old YouTube
            "video/([a-zA-Z0-9]+)",  // Vimeo
            "vimeo.com/([0-9]+)"  // Vimeo direct
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
               let range = Range(match.range(at: 1), in: url) {
                return String(url[range])
            }
        }
        
        // Use URL as ID if no pattern matches
        return nil
    }
}
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
        let downloadPath: String
        let timestamp: Date
        let fileSize: Int64?
        let duration: Double?
        
        // Hash only on videoId for duplicate detection
        func hash(into hasher: inout Hasher) {
            hasher.combine(videoId)
        }
        
        static func == (lhs: DownloadRecord, rhs: DownloadRecord) -> Bool {
            lhs.videoId == rhs.videoId
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
        
        historyFile = appFolder.appendingPathComponent("download_history.json")
        
        loadHistory()
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
                      downloadPath: String, fileSize: Int64? = nil, 
                      duration: Double? = nil) {
        let record = DownloadRecord(
            videoId: videoId,
            url: url,
            title: title,
            downloadPath: downloadPath,
            timestamp: Date(),
            fileSize: fileSize,
            duration: duration
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
    
    // Clear history
    func clearHistory() {
        history.removeAll()
        saveHistory()
    }
    
    // Clear old records (older than days specified)
    func clearOldRecords(olderThanDays: Int) {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -olderThanDays, to: Date())!
        history = history.filter { $0.timestamp > cutoffDate }
        saveHistory()
    }
    
    // Check if file still exists at download path
    func verifyDownloadExists(_ record: DownloadRecord) -> Bool {
        FileManager.default.fileExists(atPath: record.downloadPath)
    }
    
    // Remove records for deleted files
    func cleanupDeletedFiles() {
        history = history.filter { verifyDownloadExists($0) }
        saveHistory()
    }
    
    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: historyFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: historyFile)
            let records = try JSONDecoder().decode([DownloadRecord].self, from: data)
            history = Set(records)
        } catch {
            print("Failed to load download history: \(error)")
        }
    }
    
    private func saveHistory() {
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
import Foundation
import AppKit
import Combine

// Simple download task for queue system (legacy - kept for compatibility)
class QueueDownloadTaskLegacy: ObservableObject {
    let url: String
    @Published var progress: Double = 0
    @Published var status: String = ""
    @Published var speed: String = ""
    @Published var eta: String = ""
    var process: Process?
    
    init(url: String) {
        self.url = url
    }
    
    func cancel() {
        process?.terminate()
    }
}

// Alias for compatibility with CompactQueueView
typealias QueueDownloadTask = QueueItem

@MainActor
class DownloadQueue: ObservableObject {
    @Published var items: [QueueItem] = []
    @Published var currentDownload: QueueItem?
    @Published var downloadLocation: URL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
    @Published var useConsistentFormat = false
    @Published var consistentFormatType: FormatType = .bestVideo
    @Published var isPaused = false  // Global pause state for queue
    @Published var maxConcurrentDownloads = 3 {
        didSet {
            UserDefaults.standard.set(maxConcurrentDownloads, forKey: "maxConcurrentDownloads")
            processQueue()
        }
    }
    
    private let ytdlpService = YTDLPService()
    private let preferences = AppPreferences.shared
    private var cancellables = Set<AnyCancellable>()
    private var itemCancellables: [UUID: AnyCancellable] = [:] // Track item-specific subscriptions
    private var activeDownloads: Set<UUID> = []
    
    init() {
        // Use the preferences system for download location
        if !preferences.downloadPath.isEmpty {
            downloadLocation = URL(fileURLWithPath: preferences.resolvedDownloadPath)
        }
        loadSettings()
        
        // Observe preference changes using Combine on the ObservableObject
        preferences.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    if !self.preferences.downloadPath.isEmpty {
                        self.downloadLocation = URL(fileURLWithPath: self.preferences.resolvedDownloadPath)
                        // Update waiting items with new location
                        self.updateWaitingItemsLocation()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Queue Management
    
    func addToQueue(url: String, format: VideoFormat?, videoInfo: VideoInfo) {
        // Determine format to use
        let formatToUse: VideoFormat?
        if useConsistentFormat {
            // Use format type to select best format for this video
            formatToUse = consistentFormatType.getBestFormat(from: videoInfo.formats ?? [])
        } else {
            formatToUse = format
        }
        
        // Determine download location based on format type and preferences
        let itemDownloadLocation: URL
        if preferences.useSeparateLocations {
            if preferences.downloadAudio || (formatToUse?.acodec != nil && formatToUse?.vcodec == "none") {
                // Audio-only download
                itemDownloadLocation = URL(fileURLWithPath: preferences.resolvedAudioPath)
            } else if formatToUse?.vcodec != nil && formatToUse?.acodec == "none" {
                // Video-only download
                itemDownloadLocation = URL(fileURLWithPath: preferences.resolvedVideoOnlyPath)
            } else {
                // Merged/complete file
                itemDownloadLocation = downloadLocation
            }
        } else {
            itemDownloadLocation = downloadLocation
        }
        
        let item = QueueItem(
            url: url,
            format: formatToUse,
            videoInfo: videoInfo,
            downloadLocation: itemDownloadLocation
        )
        
        // Subscribe to item changes to trigger queue updates with weak references
        let cancellable = item.objectWillChange
            .sink { [weak self, weak item] _ in
                guard let self = self, item != nil else { return }
                self.objectWillChange.send()
            }
        // Store with item ID for proper cleanup
        itemCancellables[item.id] = cancellable
        
        items.append(item)
        
        // Only process queue if not paused
        if !isPaused {
            processQueue()
        }
    }
    
    func removeFromQueue(_ item: QueueItem) {
        if item.status == .downloading {
            cancelDownload(item)
        }
        // Clean up the item's subscription to prevent memory leak
        itemCancellables[item.id]?.cancel()
        itemCancellables.removeValue(forKey: item.id)
        items.removeAll { $0.id == item.id }
    }
    
    // Alias for CompactQueueView compatibility
    func removeItem(_ item: QueueItem) {
        removeFromQueue(item)
    }
    
    func prioritizeItem(_ item: QueueItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              index > 0,
              item.status == .waiting else { return }
        
        // Move item up in the queue
        items.move(fromOffsets: IndexSet(integer: index), toOffset: 0)
    }
    
    func deprioritizeItem(_ item: QueueItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }),
              index < items.count - 1,
              item.status == .waiting else { return }
        
        // Move item down in the queue
        items.move(fromOffsets: IndexSet(integer: index), toOffset: items.count)
    }
    
    func pauseDownload(_ item: QueueItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].status = .paused
        cancelDownload(item)
    }
    
    func resumeDownload(_ item: QueueItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].status = .waiting
        processQueue()
    }
    
    func clearCompleted() {
        let itemsToRemove = items.filter { $0.status == .completed || $0.status == .failed }
        // Clean up subscriptions for removed items
        for item in itemsToRemove {
            itemCancellables[item.id]?.cancel()
            itemCancellables.removeValue(forKey: item.id)
        }
        items.removeAll { $0.status == .completed || $0.status == .failed }
    }
    
    deinit {
        // Clean up all subscriptions to prevent memory leaks
        cancellables.forEach { $0.cancel() }
        cancellables.removeAll()
        
        itemCancellables.values.forEach { $0.cancel() }
        itemCancellables.removeAll()
    }
    
    func moveItem(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0 && sourceIndex < items.count,
              destinationIndex >= 0 && destinationIndex < items.count else {
            return
        }
        
        let item = items.remove(at: sourceIndex)
        items.insert(item, at: destinationIndex)
    }
    
    func retryFailed() {
        for index in items.indices {
            if items[index].status == .failed {
                items[index].status = .waiting
                items[index].progress = 0
                items[index].errorMessage = nil
            }
        }
        processQueue()
    }
    
    // Public method for CompactQueueView to start a specific download
    func startDownload(_ item: QueueItem) {
        guard item.status == .waiting else { return }
        processQueue()
    }
    
    // Public method for CompactQueueView to retry a specific download
    func retryDownload(_ item: QueueItem) {
        guard item.status == .failed else { return }
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].status = .waiting
            items[index].progress = 0
            
            // Check if this was a format error - keep the error message if format was changed
            if let error = items[index].errorMessage, 
               error.contains("Using alternative format") {
                // Keep the message so user knows alternative format is being used
                items[index].errorMessage = nil
            } else {
                items[index].errorMessage = nil
            }
        }
        processQueue()
    }
    
    // Retry with different format
    func retryWithFormat(_ item: QueueItem, format: VideoFormat) {
        guard item.status == .failed else { return }
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].format = format
            items[index].status = .waiting
            items[index].progress = 0
            items[index].errorMessage = "Retrying with: \(format.qualityLabel)"
            
            DebugLogger.shared.log(
                "Manual format retry",
                level: .info,
                details: "Using format: \(format.format_id) - \(format.qualityLabel)"
            )
        }
        processQueue()
    }
    
    // MARK: - Download Processing
    
    func processQueue() {
        // Don't process if queue is paused
        guard !isPaused else { return }
        
        Task {
            // Start multiple downloads up to the limit
            while activeDownloads.count < maxConcurrentDownloads {
                guard let nextItem = items.first(where: { $0.status == .waiting }) else {
                    break
                }
                
                // Start download without await to allow concurrent execution
                Task {
                    await startDownload(nextItem)
                }
                
                // Brief delay to prevent race conditions
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            }
        }
    }
    
    // Toggle pause/resume for the queue
    func togglePause() {
        isPaused.toggle()
        
        if isPaused {
            // Pause all active downloads
            for item in items where item.status == .downloading {
                pauseDownload(item)
            }
        } else {
            // Resume processing
            processQueue()
        }
    }
    
    private func startDownload(_ item: QueueItem) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        items[index].status = .downloading
        activeDownloads.insert(item.id)
        
        // Create download task with simplified properties for queue
        let downloadTask = QueueDownloadTaskLegacy(url: item.url)
        items[index].downloadTask = downloadTask
        
        // Create a separate cancellable set for this download
        var downloadCancellables = Set<AnyCancellable>()
        
        // Subscribe to progress updates with weak references
        downloadTask.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] progress in
                guard let self = self, let item = item,
                      let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return }
                self.items[idx].progress = progress
            }
            .store(in: &downloadCancellables)
        
        downloadTask.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] status in
                guard let self = self, let item = item,
                      let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return }
                self.items[idx].downloadStatus = status
            }
            .store(in: &downloadCancellables)
        
        downloadTask.$speed
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] speed in
                guard let self = self, let item = item,
                      let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return }
                self.items[idx].speed = speed
            }
            .store(in: &downloadCancellables)
        
        downloadTask.$eta
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak item] eta in
                guard let self = self, let item = item,
                      let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return }
                self.items[idx].eta = eta
            }
            .store(in: &downloadCancellables)
        
        // Store download-specific cancellables temporarily
        self.cancellables.formUnion(downloadCancellables)
        
        // Start the download
        do {
            try await ytdlpService.downloadVideo(
                url: item.url,
                format: item.format,
                outputPath: item.downloadLocation.path,
                downloadTask: item  // Pass the item itself since QueueDownloadTask is now an alias for QueueItem
            )
            
            await MainActor.run {
                if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[idx].status = .completed
                    self.items[idx].progress = 100
                    
                    // Add to download history with full metadata
                    let videoId = self.extractVideoId(from: item.url) ?? item.url
                    // Use actualFilePath if available, otherwise fall back to downloadLocation
                    let downloadDir = item.downloadLocation.path
                    let actualFile = item.actualFilePath?.path
                    
                    // Get file size if file exists
                    var fileSize: Int64?
                    if let actualPath = actualFile {
                        if let attributes = try? FileManager.default.attributesOfItem(atPath: actualPath) {
                            fileSize = attributes[.size] as? Int64
                        }
                    }
                    
                    DownloadHistory.shared.addToHistory(
                        videoId: videoId,
                        url: item.url,
                        title: item.title,
                        downloadPath: downloadDir,
                        actualFilePath: actualFile,
                        fileSize: fileSize,
                        duration: item.videoInfo.duration,
                        thumbnail: item.videoInfo.thumbnail,
                        uploader: item.videoInfo.uploader
                    )
                    
                    // Update dock menu
                    DockMenuService.shared.notifyDownloadCompleted()
                }
                self.activeDownloads.remove(item.id)
                self.processQueue()
            }
        } catch {
            await MainActor.run {
                if let idx = self.items.firstIndex(where: { $0.id == item.id }) {
                    self.items[idx].status = .failed
                    self.items[idx].errorMessage = error.localizedDescription
                    DebugLogger.shared.log("Download failed for: \(item.title)", level: .error, details: error.localizedDescription)
                }
                self.activeDownloads.remove(item.id)
                // Don't automatically retry failed items
                self.processQueue()
            }
        }
    }
    
    func cancelDownload(_ item: QueueItem) {
        // Terminate the yt-dlp process
        if let task = item.downloadTask {
            task.process?.terminate()
        }
        
        // Update item status
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].status = .failed
            items[index].errorMessage = "Cancelled by user"
            items[index].downloadStatus = "Cancelled"
        }
        
        activeDownloads.remove(item.id)
        
        // Process next item in queue
        processQueue()
    }
    
    // MARK: - Helper Methods
    
    private func extractVideoId(from url: String) -> String? {
        // Extract video ID from various URL formats
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
        
        return nil
    }
    
    // MARK: - Save Location Management
    
    func setSaveLocation(_ url: URL) {
        downloadLocation = url
        preferences.downloadPath = url.path
        updateWaitingItemsLocation()
    }
    
    private func updateWaitingItemsLocation() {
        // Update existing waiting items with new location
        for index in items.indices {
            if items[index].status == .waiting {
                items[index].downloadLocation = downloadLocation
            }
        }
    }
    
    // MARK: - Settings Management
    
    func setConsistentFormatType(_ type: FormatType) {
        consistentFormatType = type
        UserDefaults.standard.set(type.rawValue, forKey: "consistentFormatType")
    }
    
    private func loadSettings() {
        // Load max concurrent downloads
        let savedMax = UserDefaults.standard.integer(forKey: "maxConcurrentDownloads")
        if savedMax > 0 && savedMax <= 10 {
            maxConcurrentDownloads = savedMax
        }
        
        // Load consistent format settings
        useConsistentFormat = UserDefaults.standard.bool(forKey: "useConsistentFormat")
        if let savedType = UserDefaults.standard.string(forKey: "consistentFormatType"),
           let type = FormatType(rawValue: savedType) {
            consistentFormatType = type
        }
    }
    
}

// MARK: - Queue Item Model

class QueueItem: Identifiable, ObservableObject, Equatable {
    let id = UUID()
    let url: String
    @Published var format: VideoFormat?
    var videoInfo: VideoInfo
    var downloadLocation: URL
    
    @Published var status: DownloadStatus = .waiting
    @Published var progress: Double = 0
    @Published var downloadStatus: String = ""
    @Published var speed: String = ""
    @Published var eta: String = ""
    @Published var errorMessage: String?
    var downloadTask: QueueDownloadTaskLegacy?
    @Published var actualFilePath: URL?  // Actual downloaded file path
    @Published var extractedAudioPath: URL?  // Path to extracted audio file
    
    init(url: String, format: VideoFormat?, videoInfo: VideoInfo, downloadLocation: URL) {
        self.url = url
        self.format = format
        self.videoInfo = videoInfo
        self.downloadLocation = downloadLocation
    }
    
    var title: String {
        videoInfo.title
    }
    
    var thumbnail: String? {
        videoInfo.thumbnail
    }
    
    var formatDescription: String {
        if let format = format {
            return "\(format.qualityLabel) • \(format.ext.uppercased())"
        }
        return "Best Quality"
    }
    
    static func == (lhs: QueueItem, rhs: QueueItem) -> Bool {
        lhs.id == rhs.id
    }
    
    // Computed properties for CompactQueueView compatibility
    var selectedFormat: VideoFormat? { format }
    var statusMessage: String {
        switch status {
        case .waiting: return "Waiting"
        case .downloading: return downloadStatus.isEmpty ? "Downloading..." : downloadStatus
        case .completed: return "Completed"
        case .failed: return errorMessage ?? "Failed"
        case .paused: return "Paused"
        }
    }
}

enum DownloadStatus {
    case waiting
    case downloading
    case paused
    case completed
    case failed
    
    var displayText: String {
        switch self {
        case .waiting: return "Waiting"
        case .downloading: return "Downloading"
        case .paused: return "Paused"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }
    
    var color: NSColor {
        switch self {
        case .waiting: return .tertiaryLabelColor
        case .downloading: return .systemBlue
        case .paused: return .systemOrange
        case .completed: return .systemGreen
        case .failed: return .systemRed
        }
    }
}


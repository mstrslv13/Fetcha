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
    @Published var maxConcurrentDownloads = 3 {
        didSet {
            UserDefaults.standard.set(maxConcurrentDownloads, forKey: "maxConcurrentDownloads")
            processQueue()
        }
    }
    
    private let ytdlpService = YTDLPService()
    private let preferences = AppPreferences.shared
    private var cancellables = Set<AnyCancellable>()
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
        items.append(item)
        processQueue()
    }
    
    func removeFromQueue(_ item: QueueItem) {
        if item.status == .downloading {
            cancelDownload(item)
        }
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
        items.removeAll { $0.status == .completed || $0.status == .failed }
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
            items[index].errorMessage = nil
        }
        processQueue()
    }
    
    // MARK: - Download Processing
    
    func processQueue() {
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
    
    private func startDownload(_ item: QueueItem) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        
        items[index].status = .downloading
        activeDownloads.insert(item.id)
        
        // Create download task with simplified properties for queue
        let downloadTask = QueueDownloadTaskLegacy(url: item.url)
        items[index].downloadTask = downloadTask
        
        // Subscribe to progress updates
        downloadTask.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                guard let self = self,
                      let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return }
                self.items[idx].progress = progress
            }
            .store(in: &cancellables)
        
        downloadTask.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self,
                      let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return }
                self.items[idx].downloadStatus = status
            }
            .store(in: &cancellables)
        
        downloadTask.$speed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speed in
                guard let self = self,
                      let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return }
                self.items[idx].speed = speed
            }
            .store(in: &cancellables)
        
        downloadTask.$eta
            .receive(on: DispatchQueue.main)
            .sink { [weak self] eta in
                guard let self = self,
                      let idx = self.items.firstIndex(where: { $0.id == item.id }) else { return }
                self.items[idx].eta = eta
            }
            .store(in: &cancellables)
        
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
                    
                    // Add to download history
                    let videoId = self.extractVideoId(from: item.url) ?? item.url
                    DownloadHistory.shared.addToHistory(
                        videoId: videoId,
                        url: item.url,
                        title: item.title,
                        downloadPath: item.downloadLocation.path,
                        fileSize: nil,  // Could be extracted from download info
                        duration: item.videoInfo.duration
                    )
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
        item.downloadTask?.cancel()
        activeDownloads.remove(item.id)
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
    let videoInfo: VideoInfo
    var downloadLocation: URL
    
    @Published var status: DownloadStatus = .waiting
    @Published var progress: Double = 0
    @Published var downloadStatus: String = ""
    @Published var speed: String = ""
    @Published var eta: String = ""
    @Published var errorMessage: String?
    var downloadTask: QueueDownloadTaskLegacy?
    
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


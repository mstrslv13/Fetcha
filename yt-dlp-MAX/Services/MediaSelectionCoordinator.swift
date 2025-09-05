import Foundation
import SwiftUI

// Coordinator to manage media selection across different panels
class MediaSelectionCoordinator: ObservableObject {
    static let shared = MediaSelectionCoordinator()
    
    @Published var selectedHistoryItem: DownloadHistory.DownloadRecord?
    @Published var selectedQueueItem: QueueDownloadTask?
    @Published var currentMediaItem: DownloadHistory.DownloadRecord?
    
    private init() {}
    
    func selectHistoryItem(_ item: DownloadHistory.DownloadRecord) {
        selectedHistoryItem = item
        currentMediaItem = item
        selectedQueueItem = nil  // Clear queue selection
    }
    
    func selectQueueItem(_ item: QueueDownloadTask) {
        selectedQueueItem = item
        // Don't change media item when selecting from queue
        selectedHistoryItem = nil  // Clear history selection
    }
    
    func setCurrentMediaItem(_ item: DownloadHistory.DownloadRecord?) {
        currentMediaItem = item
    }
    
    func clearSelection() {
        selectedHistoryItem = nil
        selectedQueueItem = nil
        currentMediaItem = nil
    }
}
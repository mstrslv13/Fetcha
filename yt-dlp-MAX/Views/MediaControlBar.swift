import SwiftUI
import AppKit

struct MediaControlBar: View {
    @ObservedObject var queue: DownloadQueue
    @ObservedObject var downloadHistory: DownloadHistory
    @StateObject private var coordinator = MediaSelectionCoordinator.shared
    @State private var currentIndex: Int = -1
    @State private var currentFile: DownloadHistory.DownloadRecord?
    @State private var isNavigatingHistory = false  // Track if we're navigating history
    
    // Get completed downloads from queue and history
    private var completedDownloads: [DownloadHistory.DownloadRecord] {
        // Get recently completed items from queue
        let recentCompleted = queue.items
            .filter { $0.status == .completed }
            .compactMap { item -> DownloadHistory.DownloadRecord? in
                // Create a record from queue item
                let videoId = extractVideoId(from: item.url) ?? item.url
                
                // Use actual file path if available
                let downloadPath = item.actualFilePath?.path ?? item.downloadLocation.path
                
                return DownloadHistory.DownloadRecord(
                    videoId: videoId,
                    url: item.url,
                    title: item.title,
                    downloadPath: downloadPath,
                    timestamp: Date(),
                    fileSize: nil,
                    duration: item.videoInfo.duration
                )
            }
        
        // Combine with history and sort by timestamp
        let allDownloads = Array(downloadHistory.history) + recentCompleted
        
        // Remove duplicates based on videoId
        let uniqueDownloads = Array(Set(allDownloads))
        
        return uniqueDownloads
            .filter { downloadHistory.verifyDownloadExists($0) }
            .sorted { $0.timestamp > $1.timestamp }  // Most recent first
            .reversed()  // Oldest first for navigation
    }
    
    private var hasPrevious: Bool {
        currentIndex > 0 && !completedDownloads.isEmpty
    }
    
    private var hasNext: Bool {
        currentIndex < completedDownloads.count - 1 && currentIndex >= 0
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Previous button
            Button(action: previousFile) {
                Image(systemName: "backward.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .disabled(!hasPrevious)
            .help("Previous download")
            .keyboardShortcut(.leftArrow, modifiers: [.command])
            
            // Play/Open button
            Button(action: playCurrentFile) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .disabled(currentFile == nil)
            .help("Open current file")
            .keyboardShortcut(.space, modifiers: [])
            
            // Stop button (clears selection)
            Button(action: stopPlayback) {
                Image(systemName: "stop.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .disabled(currentFile == nil)
            .help("Clear selection")
            
            // Next button
            Button(action: nextFile) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            .disabled(!hasNext)
            .help("Next download")
            .keyboardShortcut(.rightArrow, modifiers: [.command])
            
            Divider()
                .frame(height: 20)
            
            // Current file display
            if let file = currentFile {
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(file.title)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        
                        // Show actual filename if available
                        if !file.filename.isEmpty && file.filename != file.title {
                            Text(file.filename)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                    
                    if !completedDownloads.isEmpty {
                        Text("(\(currentIndex + 1)/\(completedDownloads.count))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Show in Finder button
                Button(action: showInFinder) {
                    Image(systemName: "folder")
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help("Show in Finder")
            } else {
                Text("No completed downloads")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
            
            // Download count - dynamically show actual count
            if !completedDownloads.isEmpty {
                Label("\(completedDownloads.count) completed", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            // Initialize with the first completed download
            if !completedDownloads.isEmpty && currentIndex < 0 {
                currentIndex = 0
                currentFile = completedDownloads[0]
                coordinator.setCurrentMediaItem(currentFile)
            }
        }
        .onChange(of: completedDownloads.count) { oldValue, newValue in
            // Update current file if new downloads complete
            if currentIndex >= 0 && currentIndex < completedDownloads.count {
                currentFile = completedDownloads[currentIndex]
            } else if currentIndex >= completedDownloads.count && !completedDownloads.isEmpty {
                // Adjust index if it's out of bounds
                currentIndex = completedDownloads.count - 1
                currentFile = completedDownloads[currentIndex]
            }
            coordinator.setCurrentMediaItem(currentFile)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HistoryItemSelected"))) { notification in
            // Handle selection from history panel
            if let item = notification.userInfo?["item"] as? DownloadHistory.DownloadRecord {
                // Find the item in our list and set it as current
                if let index = completedDownloads.firstIndex(where: { $0.videoId == item.videoId }) {
                    currentIndex = index
                    currentFile = item
                    isNavigatingHistory = true
                    coordinator.setCurrentMediaItem(currentFile)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("QueueItemSelected"))) { notification in
            // Handle selection from queue - maintain independent state
            // Don't change our selection when queue selection changes
            isNavigatingHistory = false
        }
    }
    
    // MARK: - Navigation Functions
    
    private func previousFile() {
        guard hasPrevious else { return }
        currentIndex -= 1
        currentFile = completedDownloads[currentIndex]
        coordinator.setCurrentMediaItem(currentFile)
    }
    
    private func nextFile() {
        guard hasNext else { return }
        currentIndex += 1
        currentFile = completedDownloads[currentIndex]
        coordinator.setCurrentMediaItem(currentFile)
    }
    
    private func playCurrentFile() {
        guard let file = currentFile else { return }
        
        // Use the DownloadHistory method to find the actual file
        if let actualFileURL = DownloadHistory.shared.findActualFile(for: file) {
            // Open the file
            NSWorkspace.shared.open(actualFileURL)
            
            DebugLogger.shared.log(
                "Opened file: \(file.title)",
                level: .info,
                details: "Path: \(actualFileURL.path)"
            )
        } else {
            // File not found, try to show the directory
            let url = URL(fileURLWithPath: file.resolvedFilePath)
            var isDirectory: ObjCBool = false
            
            if FileManager.default.fileExists(atPath: file.resolvedFilePath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Open the directory
                    NSWorkspace.shared.open(url)
                } else {
                    // Show the file in Finder (it might exist but be unplayable)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } else {
                // Show parent directory
                let parentURL = url.deletingLastPathComponent()
                if FileManager.default.fileExists(atPath: parentURL.path) {
                    NSWorkspace.shared.open(parentURL)
                }
                
                DebugLogger.shared.log(
                    "File not found: \(file.title)",
                    level: .warning,
                    details: "Path: \(file.resolvedFilePath)"
                )
            }
        }
    }
    
    private func stopPlayback() {
        // Don't reset navigation state, just clear the current playback
        // Keep currentIndex and allow navigation to continue
        // This prevents the stop button from breaking navigation
        coordinator.setCurrentMediaItem(nil)
    }
    
    private func showInFinder() {
        guard let file = currentFile else { return }
        
        // Use the DownloadHistory method to find the actual file
        if let actualFileURL = DownloadHistory.shared.findActualFile(for: file) {
            // File exists, select it in Finder
            NSWorkspace.shared.activateFileViewerSelecting([actualFileURL])
        } else {
            // File doesn't exist, try to open the directory
            let url = URL(fileURLWithPath: file.resolvedFilePath)
            var isDirectory: ObjCBool = false
            
            if FileManager.default.fileExists(atPath: file.resolvedFilePath, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Open the directory
                    NSWorkspace.shared.open(url)
                } else {
                    // Show the file location
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            } else {
                // Open parent folder
                let parentURL = url.deletingLastPathComponent()
                if FileManager.default.fileExists(atPath: parentURL.path) {
                    NSWorkspace.shared.open(parentURL)
                }
            }
        }
    }
    
    // Extract video ID helper (matches DownloadHistory implementation)
    private func extractVideoId(from url: String) -> String? {
        let patterns = [
            "v=([a-zA-Z0-9_-]{11})",
            "youtu.be/([a-zA-Z0-9_-]{11})",
            "embed/([a-zA-Z0-9_-]{11})",
            "/v/([a-zA-Z0-9_-]{11})",
            "video/([a-zA-Z0-9]+)",
            "vimeo.com/([0-9]+)"
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
}
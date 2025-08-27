import SwiftUI

struct CompactQueueView: View {
    @ObservedObject var queue: DownloadQueue
    @State private var selectedItem: QueueDownloadTask?
    
    var body: some View {
        VStack(spacing: 0) {
            // Queue header
            HStack {
                Text("Download Queue")
                    .font(.headline)
                Spacer()
                
                // Queue stats
                if !queue.items.isEmpty {
                    HStack(spacing: 15) {
                        Label("\(queue.items.filter { $0.status == .downloading }.count)", systemImage: "arrow.down.circle.fill")
                            .foregroundColor(.accentColor)
                        Label("\(queue.items.filter { $0.status == .completed }.count)", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(queue.items.filter { $0.status == .waiting }.count)", systemImage: "clock")
                            .foregroundColor(.secondary)
                    }
                    .font(.caption)
                }
                
                Button(action: {
                    queue.clearCompleted()
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
                .disabled(queue.items.filter { $0.status == .completed }.isEmpty)
                .help("Clear completed downloads")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Queue items
            if queue.items.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Queue is empty")
                        .foregroundColor(.secondary)
                    Text("Paste a URL to start downloading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(spacing: 2) {
                        ForEach(queue.items) { item in
                            CompactQueueItemView(item: item, isSelected: selectedItem?.id == item.id)
                                .onTapGesture {
                                    selectedItem = item
                                }
                                .contextMenu {
                                    contextMenu(for: item)
                                }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private func contextMenu(for item: QueueDownloadTask) -> some View {
        // File actions
        if item.status == .completed {
            Button("Reveal in Finder") {
                revealInFinder(item)
            }
            
            Button("Open Media") {
                openMedia(item)
            }
            
            Divider()
        }
        
        Button("Copy Title") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.title, forType: .string)
        }
        
        Divider()
        
        // Download control
        if item.status == .waiting {
            Button("Prioritize") {
                queue.prioritizeItem(item)
            }
            
            Button("Deprioritize") {
                queue.deprioritizeItem(item)
            }
            
            Divider()
            
            Button("Start Now") {
                queue.startDownload(item)
            }
        } else if item.status == .downloading {
            Button("Pause") {
                queue.pauseDownload(item)
            }
        } else if item.status == .paused {
            Button("Resume") {
                queue.resumeDownload(item)
            }
        }
        
        if item.status == .failed {
            Button("Retry") {
                queue.retryDownload(item)
            }
        }
        
        if item.status == .completed {
            Button("Re-download") {
                queue.retryDownload(item)
            }
        }
        
        if item.status == .completed {
            Menu("Change Format") {
                // Get unique heights from available formats
                let availableHeights = Set(item.videoInfo.formats?.compactMap { $0.height } ?? [])
                    .sorted(by: >)  // Sort descending
                
                // Show available video qualities
                ForEach(availableHeights, id: \.self) { height in
                    Button("\(height)p") {
                        redownloadWithFormat(item, quality: "\(height)p")
                    }
                    .disabled(item.selectedFormat?.height == height)
                }
                
                Divider()
                
                // Audio only option if audio formats exist
                if item.videoInfo.formats?.contains(where: { 
                    $0.acodec != nil && $0.acodec != "none" && 
                    ($0.vcodec == nil || $0.vcodec == "none") 
                }) == true {
                    Button("Audio Only") {
                        redownloadWithFormat(item, quality: "Audio Only")
                    }
                    .disabled(item.selectedFormat?.vcodec == nil || item.selectedFormat?.vcodec == "none")
                }
            }
        }
        
        Divider()
        
        Button("Add Metadata") {
            // FUTURE: Phase 5 - Manual metadata editing
            // Will allow users to edit title, description, tags
            // Integration point for semansex metadata enrichment
        }
        .disabled(true)
        
        Button("Infer") {
            // FUTURE: Evolution Stage B - AI-powered features
            // Will use semansex to infer metadata, categorize content
            // Auto-tag videos based on content analysis
        }
        .disabled(true)
        
        Divider()
        
        Button("Remove from Queue") {
            queue.removeItem(item)
        }
        
        if item.status == .completed {
            Button("Delete File") {
                deleteFile(item)
            }
            .foregroundColor(.red)
        }
    }
    
    private func revealInFinder(_ item: QueueDownloadTask) {
        // Try to find the actual downloaded file
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(atPath: item.downloadLocation.path) {
            // Clean the title for matching
            let cleanTitle = item.title.replacingOccurrences(of: "/", with: "_")
                                       .replacingOccurrences(of: ":", with: "_")
            
            // Find files that contain the video title
            for file in files {
                if file.localizedCaseInsensitiveContains(cleanTitle) || 
                   file.localizedCaseInsensitiveContains(item.videoInfo.title) {
                    let fullPath = "\(item.downloadLocation.path)/\(file)"
                    // Select the specific file in Finder
                    NSWorkspace.shared.selectFile(fullPath, inFileViewerRootedAtPath: item.downloadLocation.path)
                    return
                }
            }
        }
        // Fallback to just opening the folder
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: item.downloadLocation.path)
    }
    
    private func openMedia(_ item: QueueDownloadTask) {
        // Try to find and open the downloaded file
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(atPath: item.downloadLocation.path) {
            let cleanTitle = item.title.replacingOccurrences(of: "/", with: "_")
                                       .replacingOccurrences(of: ":", with: "_")
            
            for file in files {
                if file.localizedCaseInsensitiveContains(cleanTitle) ||
                   file.localizedCaseInsensitiveContains(item.videoInfo.title) {
                    let fullPath = "\(item.downloadLocation.path)/\(file)"
                    NSWorkspace.shared.open(URL(fileURLWithPath: fullPath))
                    break
                }
            }
        }
    }
    
    private func redownloadWithFormat(_ item: QueueDownloadTask, quality: String) {
        // Re-add to queue with different format
        var newFormat: VideoFormat?
        
        if quality == "Audio Only" {
            // Find best audio-only format based on user preference
            let preferences = AppPreferences.shared
            let preferredAudioFormat = preferences.audioFormat
            
            // First try to find the preferred format
            newFormat = item.videoInfo.formats?.first { format in
                format.acodec != nil && format.acodec != "none" && 
                (format.vcodec == nil || format.vcodec == "none") &&
                (format.ext == preferredAudioFormat || 
                 (preferredAudioFormat == "mp3" && format.acodec == "mp3") ||
                 (preferredAudioFormat == "m4a" && (format.ext == "m4a" || format.acodec == "aac")) ||
                 (preferredAudioFormat == "flac" && format.ext == "flac") ||
                 (preferredAudioFormat == "wav" && format.ext == "wav") ||
                 (preferredAudioFormat == "opus" && (format.ext == "opus" || format.acodec == "opus")) ||
                 (preferredAudioFormat == "vorbis" && (format.ext == "ogg" || format.acodec == "vorbis")))
            }
            
            // If preferred format not found, find best audio-only format
            if newFormat == nil {
                newFormat = item.videoInfo.formats?.filter { format in
                    format.acodec != nil && format.acodec != "none" && 
                    (format.vcodec == nil || format.vcodec == "none")
                }.sorted { ($0.abr ?? 0) > ($1.abr ?? 0) }.first
            }
        } else {
            // Find format with the requested quality
            let height = Int(quality.replacingOccurrences(of: "p", with: "")) ?? 1080
            
            // First try to find a format with both video and audio at the requested height
            newFormat = item.videoInfo.formats?.first { format in
                format.height == height && 
                format.vcodec != nil && format.vcodec != "none" &&
                format.acodec != nil && format.acodec != "none"
            }
            
            // If not found, look for video-only format that we can merge with audio
            if newFormat == nil {
                newFormat = item.videoInfo.formats?.first { format in
                    format.height == height && 
                    format.vcodec != nil && format.vcodec != "none"
                }
            }
        }
        
        // Only add if we found a different format
        if let newFormat = newFormat, newFormat.format_id != item.selectedFormat?.format_id {
            queue.addToQueue(url: item.url, format: newFormat, videoInfo: item.videoInfo)
        }
    }
    
    private func deleteFile(_ item: QueueDownloadTask) {
        // Delete associated file
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(atPath: item.downloadLocation.path) {
            for file in files {
                if file.contains(item.title) {
                    let fullPath = "\(item.downloadLocation.path)/\(file)"
                    try? fm.removeItem(atPath: fullPath)
                }
            }
        }
        queue.removeItem(item)
    }
}

struct CompactQueueItemView: View {
    @ObservedObject var item: QueueDownloadTask
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Status icon
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 20)
            
            // Video info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let format = item.selectedFormat {
                        // Enhanced format display with codecs
                        HStack(spacing: 2) {
                            Text(format.qualityLabel)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            Text(format.ext.uppercased())
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if let vcodec = format.vcodec, vcodec != "none" {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(vcodec)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let acodec = format.acodec, acodec != "none" {
                                Text("/")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(acodec)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if item.status == .downloading {
                        Text("• \(Int(item.progress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                        
                        if !item.speed.isEmpty {
                            Text("• \(item.speed)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if !item.eta.isEmpty {
                            Text("• \(item.eta)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Text("• \(item.statusMessage)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Progress or action button
            if item.status == .downloading {
                CircularProgressView(progress: item.progress)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .background(item.status == .downloading ? Color.accentColor.opacity(0.05) : Color.clear)
    }
    
    private var statusIcon: String {
        switch item.status {
        case .waiting: return "clock"
        case .downloading: return "arrow.down.circle.fill"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch item.status {
        case .waiting: return .secondary
        case .downloading: return .accentColor
        case .completed: return .green
        case .failed: return .red
        case .paused: return .orange
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, lineWidth: 2)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: progress)
            
            Text("\(Int(progress * 100))")
                .font(.system(size: 9, weight: .medium))
        }
    }
}
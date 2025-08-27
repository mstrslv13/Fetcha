import SwiftUI
import UniformTypeIdentifiers

struct EnhancedQueueView: View {
    @ObservedObject var queue: DownloadQueue
    @Binding var selectedItem: QueueDownloadTask?
    @State private var draggedItem: QueueDownloadTask?
    @State private var selectedItems: Set<UUID> = []
    @State private var lastSelectedItem: QueueDownloadTask?
    
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
                        Label("\(queue.items.filter { $0.status == .downloading }.count)", 
                              systemImage: "arrow.down.circle.fill")
                            .foregroundColor(.accentColor)
                        Label("\(queue.items.filter { $0.status == .completed }.count)", 
                              systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Label("\(queue.items.filter { $0.status == .waiting }.count)", 
                              systemImage: "clock")
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
            
            // Queue items with drag & drop
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
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 2) {
                            ForEach(queue.items) { item in
                                EnhancedQueueItemView(
                                    item: item,
                                    isSelected: selectedItems.contains(item.id) || selectedItem?.id == item.id,
                                    isDragging: draggedItem?.id == item.id
                                )
                                .onTapGesture {
                                    handleSelection(item)
                                }
                                .simultaneousGesture(
                                    TapGesture()
                                        .modifiers(.command)
                                        .onEnded { _ in
                                            handleCommandClick(item)
                                        }
                                )
                                .simultaneousGesture(
                                    TapGesture()
                                        .modifiers(.shift)
                                        .onEnded { _ in
                                            handleShiftClick(item)
                                        }
                                )
                                .contextMenu {
                                    if selectedItems.count > 1 {
                                        multiItemContextMenu()
                                    } else {
                                        queueItemContextMenu(for: item)
                                    }
                                }
                                .onDrag {
                                    self.draggedItem = item
                                    return NSItemProvider(object: item.id.uuidString as NSString)
                                }
                                .onDrop(of: [UTType.text], delegate: QueueDropDelegate(
                                    item: item,
                                    items: queue.items,
                                    draggedItem: $draggedItem,
                                    queue: queue
                                ))
                                .id(item.id)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .onKeyDown { event in
                        handleKeyboardNavigation(event, proxy: proxy)
                    }
                }
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    @ViewBuilder
    private func queueItemContextMenu(for item: QueueDownloadTask) -> some View {
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
        
        Button("Show Details") {
            selectedItem = item
        }
        
        Button("Copy Title") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.title, forType: .string)
        }
        
        Button("Copy Download URL") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.url, forType: .string)
        }
        
        Button("Open Source Page") {
            if let url = URL(string: item.url) {
                NSWorkspace.shared.open(url)
            }
        }
        
        Divider()
        
        // Download control
        if item.status == .waiting {
            Button("Prioritize") {
                queue.prioritizeItem(item)
            }
            
            Button("Move to Bottom") {
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
            Menu("Convert Format") {
                ForEach(["1080p", "720p", "480p", "Audio Only"], id: \.self) { quality in
                    Button(quality) {
                        redownloadWithFormat(item, quality: quality)
                    }
                }
            }
        }
        
        Divider()
        
        Button("Remove from Queue") {
            queue.removeItem(item)
        }
        .foregroundColor(.red)
    }
    
    private func handleKeyboardNavigation(_ event: NSEvent, proxy: ScrollViewProxy) {
        guard let current = selectedItem,
              let currentIndex = queue.items.firstIndex(where: { $0.id == current.id }) else {
            // No selection, select first item
            if !queue.items.isEmpty {
                selectedItem = queue.items[0]
                proxy.scrollTo(queue.items[0].id)
            }
            return
        }
        
        switch event.keyCode {
        case 126: // Up arrow
            if currentIndex > 0 {
                selectedItem = queue.items[currentIndex - 1]
                proxy.scrollTo(queue.items[currentIndex - 1].id)
            }
        case 125: // Down arrow
            if currentIndex < queue.items.count - 1 {
                selectedItem = queue.items[currentIndex + 1]
                proxy.scrollTo(queue.items[currentIndex + 1].id)
            }
        default:
            break
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
    
    // MARK: - Multi-select handlers
    
    private func handleSelection(_ item: QueueDownloadTask) {
        // Normal click - select single item
        selectedItems.removeAll()
        selectedItems.insert(item.id)
        selectedItem = item
        lastSelectedItem = item
    }
    
    private func handleCommandClick(_ item: QueueDownloadTask) {
        // Cmd+Click - toggle selection
        if selectedItems.contains(item.id) {
            selectedItems.remove(item.id)
            if selectedItems.isEmpty {
                selectedItem = nil
            }
        } else {
            selectedItems.insert(item.id)
            selectedItem = item
        }
        lastSelectedItem = item
    }
    
    private func handleShiftClick(_ item: QueueDownloadTask) {
        // Shift+Click - range select
        guard let lastItem = lastSelectedItem,
              let lastIndex = queue.items.firstIndex(where: { $0.id == lastItem.id }),
              let currentIndex = queue.items.firstIndex(where: { $0.id == item.id }) else {
            handleSelection(item)
            return
        }
        
        selectedItems.removeAll()
        let range = min(lastIndex, currentIndex)...max(lastIndex, currentIndex)
        for i in range {
            selectedItems.insert(queue.items[i].id)
        }
        selectedItem = item
    }
    
    @ViewBuilder
    private func multiItemContextMenu() -> some View {
        let selectedCount = selectedItems.count
        
        Text("\(selectedCount) items selected")
            .font(.caption)
        
        Divider()
        
        // Start all waiting items
        Button("Start All") {
            for id in selectedItems {
                if let item = queue.items.first(where: { $0.id == id }),
                   item.status == .waiting {
                    queue.startDownload(item)
                }
            }
        }
        
        // Pause all downloading items
        Button("Pause All") {
            for id in selectedItems {
                if let item = queue.items.first(where: { $0.id == id }),
                   item.status == .downloading {
                    queue.pauseDownload(item)
                }
            }
        }
        
        // Retry all failed items
        Button("Retry All") {
            for id in selectedItems {
                if let item = queue.items.first(where: { $0.id == id }),
                   item.status == .failed {
                    queue.retryDownload(item)
                }
            }
        }
        
        Divider()
        
        // Remove all selected
        Button("Remove Selected") {
            for id in selectedItems {
                if let item = queue.items.first(where: { $0.id == id }) {
                    queue.removeItem(item)
                }
            }
            selectedItems.removeAll()
        }
        .foregroundColor(.red)
    }
}

struct EnhancedQueueItemView: View {
    @ObservedObject var item: QueueDownloadTask
    let isSelected: Bool
    let isDragging: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Drag handle
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary.opacity(0.5))
                .font(.caption)
                .frame(width: 15)
            
            // Enhanced status icon with animation
            ZStack {
                if item.status == .downloading {
                    Circle()
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    Circle()
                        .trim(from: 0, to: item.progress)
                        .stroke(Color.accentColor, lineWidth: 2)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.2), value: item.progress)
                        .frame(width: 24, height: 24)
                    
                    Text("\(Int(item.progress * 100))")
                        .font(.system(size: 9, weight: .medium))
                } else {
                    Image(systemName: statusIcon)
                        .foregroundColor(statusColor)
                        .font(.system(size: 16))
                }
            }
            .frame(width: 24, height: 24)
            
            // Video info with enhanced format display
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    // Enhanced format display
                    if let format = item.selectedFormat {
                        FormatBadge(format: format)
                    }
                    
                    // Status info
                    if item.status == .downloading {
                        if !item.speed.isEmpty {
                            Text("• \(item.speed)")
                                .font(.caption2)
                                .foregroundColor(.accentColor)
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
            
            // Action buttons
            if item.status == .downloading {
                Button(action: {
                    // Pause action
                }) {
                    Image(systemName: "pause.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(backgroundFor(isSelected: isSelected, isDragging: isDragging, status: item.status))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isDragging ? Color.accentColor : Color.clear, lineWidth: 2)
        )
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
    
    private func backgroundFor(isSelected: Bool, isDragging: Bool, status: DownloadStatus) -> Color {
        if isDragging {
            return Color.accentColor.opacity(0.2)
        } else if isSelected {
            return Color.accentColor.opacity(0.1)
        } else if status == .downloading {
            return Color.accentColor.opacity(0.05)
        } else {
            return Color.clear
        }
    }
}

struct FormatBadge: View {
    let format: VideoFormat
    
    var body: some View {
        HStack(spacing: 2) {
            Text(format.qualityLabel)
                .font(.system(size: 10, weight: .medium))
            
            Text("•")
                .font(.system(size: 10))
            
            Text(format.ext.uppercased())
                .font(.system(size: 10))
            
            if let vcodec = format.vcodec, vcodec != "none" {
                Text("•")
                    .font(.system(size: 10))
                Text(vcodec)
                    .font(.system(size: 10))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.15))
        .cornerRadius(4)
        .foregroundColor(.secondary)
    }
}

// Drag & Drop delegate
struct QueueDropDelegate: DropDelegate {
    let item: QueueDownloadTask
    let items: [QueueDownloadTask]
    @Binding var draggedItem: QueueDownloadTask?
    let queue: DownloadQueue
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard let draggedItem = draggedItem,
              draggedItem.id != item.id,
              let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id }),
              let toIndex = items.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        
        withAnimation {
            queue.moveItem(from: fromIndex, to: toIndex)
        }
    }
}

// Extension to handle keyboard events
extension View {
    func onKeyDown(perform action: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyEventHandler(action: action))
    }
}

struct KeyEventHandler: NSViewRepresentable {
    let action: (NSEvent) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyView()
        view.onKeyDown = action
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
    
    class KeyView: NSView {
        var onKeyDown: ((NSEvent) -> Void)?
        
        override var acceptsFirstResponder: Bool { true }
        
        override func keyDown(with event: NSEvent) {
            onKeyDown?(event)
        }
    }
}
import SwiftUI

struct EnhancedQueueView: View {
    @ObservedObject var queue: DownloadQueue
    @Binding var selectedItem: QueueDownloadTask?
    @State private var draggedItem: QueueDownloadTask?
    
    // Sort items: downloading first, then waiting/paused/failed, then completed
    var sortedItems: [QueueDownloadTask] {
        queue.items.sorted { item1, item2 in
            // Define sort priority (lower number = higher priority)
            func priority(for status: DownloadStatus) -> Int {
                switch status {
                case .downloading: return 0
                case .waiting: return 1
                case .paused: return 2
                case .failed: return 3
                case .completed: return 4
                }
            }
            
            let priority1 = priority(for: item1.status)
            let priority2 = priority(for: item2.status)
            
            if priority1 != priority2 {
                return priority1 < priority2
            }
            
            // If same status, maintain original order (by index in queue)
            let index1 = queue.items.firstIndex(where: { $0.id == item1.id }) ?? 0
            let index2 = queue.items.firstIndex(where: { $0.id == item2.id }) ?? 0
            return index1 < index2
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 1) {
                ForEach(sortedItems, id: \.id) { item in
                    QueueItemRow(item: item, queue: queue, isSelected: selectedItem?.id == item.id)
                        .onTapGesture {
                            selectedItem = item
                            // Notify that a queue item was selected
                            NotificationCenter.default.post(
                                name: NSNotification.Name("QueueItemSelected"),
                                object: nil,
                                userInfo: ["item": item]
                            )
                        }
                        .onDrag {
                            self.draggedItem = item
                            return NSItemProvider(object: item.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: QueueDropDelegate(
                            item: item,
                            items: $queue.items,
                            draggedItem: $draggedItem,
                            queue: queue
                        ))
                        .opacity(draggedItem?.id == item.id ? 0.5 : 1.0)
                }
            }
            .padding(.vertical, 1)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// Drop delegate for handling queue reordering
struct QueueDropDelegate: DropDelegate {
    let item: QueueDownloadTask
    @Binding var items: [QueueDownloadTask]
    @Binding var draggedItem: QueueDownloadTask?
    let queue: DownloadQueue
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedItem = draggedItem else { return false }
        
        // Only allow reordering of waiting items
        if draggedItem.status != .waiting || item.status != .waiting {
            return false
        }
        
        if draggedItem.id != item.id {
            let fromIndex = items.firstIndex(where: { $0.id == draggedItem.id })
            let toIndex = items.firstIndex(where: { $0.id == item.id })
            
            if let from = fromIndex, let to = toIndex {
                withAnimation {
                    queue.moveItem(from: from, to: to)
                }
            }
        }
        
        self.draggedItem = nil
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Visual feedback when dragging over an item
        if draggedItem?.id != item.id && draggedItem?.status == .waiting && item.status == .waiting {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                // The opacity change in the main view provides feedback
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Only allow drop on waiting items
        if item.status != .waiting || draggedItem?.status != .waiting {
            return DropProposal(operation: .forbidden)
        }
        return DropProposal(operation: .move)
    }
}

struct QueueItemRow: View {
    @ObservedObject var item: QueueDownloadTask
    @ObservedObject var queue: DownloadQueue  // Make queue observable to trigger updates
    let isSelected: Bool
    @State private var showingFormatPicker = false
    @State private var showingFormatError = false
    @StateObject private var preferences = AppPreferences.shared
    
    var statusIcon: String {
        switch item.status {
        case .waiting:
            return "clock"
        case .downloading:
            return "arrow.down.circle"
        case .paused:
            return "pause.circle"
        case .completed:
            return "checkmark.circle.fill"
        case .failed:
            return "exclamationmark.triangle"
        }
    }
    
    var statusColor: Color {
        switch item.status {
        case .waiting:
            return .secondary
        case .downloading:
            return .blue
        case .paused:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Status icon
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.system(size: 14))
                    .frame(width: 20)
                
                // Video info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 12))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        if let format = item.format {
                            Text(format.qualityLabel)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 1)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(3)
                        }
                        
                        if !item.speed.isEmpty {
                            Text(item.speed)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        if !item.eta.isEmpty {
                            Text("ETA: \(item.eta)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        // Show audio extraction indicator
                        if item.extractedAudioPath != nil {
                            HStack(spacing: 2) {
                                Image(systemName: "music.note")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                                Text("Audio extracted")
                                    .font(.system(size: 10))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Progress or actions
                if item.status == .downloading {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(item.progress))%")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                        
                        ProgressView(value: item.progress, total: 100)
                            .progressViewStyle(LinearProgressViewStyle())
                            .frame(width: 80)
                    }
                }
                
                // Control buttons
                HStack(spacing: 4) {
                    // Trash button visible when selected
                    if isSelected {
                        Button(action: {
                            if item.status == .downloading {
                                queue.cancelDownload(item)
                            }
                            queue.removeFromQueue(item)
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                        .help("Remove from queue")
                    }
                    
                    if item.status == .downloading {
                        Button(action: {
                            queue.cancelDownload(item)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                        .help("Cancel download")
                        .accessibilityLabel("Cancel Download")
                        .accessibilityHint("Stop downloading this item")
                    }
                    
                    if item.status == .paused {
                        Button(action: {
                            queue.resumeDownload(item)
                        }) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.green)
                        .help("Resume download")
                        .accessibilityLabel("Resume Download")
                        .accessibilityHint("Continue downloading this paused item")
                    }
                    
                    if item.status == .failed {
                        Button(action: {
                            queue.retryDownload(item)
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.orange)
                        .help("Retry download")
                        .accessibilityLabel("Retry Download")
                        .accessibilityHint("Try downloading this failed item again")
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .overlay(
                // Drag handle indicator for waiting items only
                HStack {
                    if item.status == .waiting {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.leading, 4)
                    }
                    Spacer()
                }
            )
            
            Divider()
                .opacity(0.5)
        }
        .contextMenu {
            // Copy URL
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url, forType: .string)
            }) {
                Label("Copy URL", systemImage: "doc.on.doc")
            }
            
            // Open in Browser
            Button(action: {
                if let url = URL(string: item.url) {
                    NSWorkspace.shared.open(url)
                }
            }) {
                Label("Open in Browser", systemImage: "safari")
            }
            
            Divider()
            
            // Change Format (only for waiting items)
            if item.status == .waiting {
                Button(action: {
                    showingFormatPicker = true
                }) {
                    Label("Change Format", systemImage: "slider.horizontal.3")
                }
            }
            
            // Pause/Resume (for downloading items)
            if item.status == .downloading {
                Button(action: {
                    queue.pauseDownload(item)
                }) {
                    Label("Pause Download", systemImage: "pause.circle")
                }
            }
            
            if item.status == .paused {
                Button(action: {
                    queue.resumeDownload(item)
                }) {
                    Label("Resume Download", systemImage: "play.circle")
                }
            }
            
            // Retry (for failed items)
            if item.status == .failed {
                Button(action: {
                    queue.retryDownload(item)
                }) {
                    Label("Retry Download", systemImage: "arrow.clockwise")
                }
                
                // If format error, show option to select different format
                if let error = item.errorMessage, 
                   (error.contains("format") || error.contains("Format") || 
                    error.contains("manual selection required")) {
                    Button(action: {
                        showingFormatError = true
                    }) {
                        Label("Select Different Format", systemImage: "slider.horizontal.3")
                    }
                }
            }
            
            // Cancel (for downloading or paused items)
            if item.status == .downloading || item.status == .paused {
                Button(action: {
                    queue.cancelDownload(item)
                }) {
                    Label("Cancel Download", systemImage: "xmark.circle")
                }
            }
            
            // Remove from Queue (for waiting or failed items)
            if item.status == .waiting || item.status == .failed {
                Button(action: {
                    queue.removeFromQueue(item)
                }) {
                    Label("Remove from Queue", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
            
            Divider()
            
            // Show in Finder (for completed, failed, or downloading items)
            if item.status == .completed || item.status == .failed || item.status == .downloading {
                Button(action: {
                    // Use actual file path if available, otherwise fall back to folder
                    let pathToReveal = item.actualFilePath ?? item.downloadLocation
                    NSWorkspace.shared.activateFileViewerSelecting([pathToReveal])
                }) {
                    Label("Show in Finder", systemImage: "folder")
                }
                
                if item.status == .completed {
                    Button(action: {
                        // Use actual file path to open the file directly
                        if let filePath = item.actualFilePath {
                            NSWorkspace.shared.open(filePath)
                        } else {
                            // Fallback: try to find the file in the download location
                            NSWorkspace.shared.open(item.downloadLocation)
                        }
                    }) {
                        Label("Open File", systemImage: "play.circle")
                    }
                    
                    // If audio was extracted, show option to open audio file
                    if let audioPath = item.extractedAudioPath {
                        Button(action: {
                            NSWorkspace.shared.open(audioPath)
                        }) {
                            Label("Open Audio File", systemImage: "music.note")
                        }
                        
                        Button(action: {
                            NSWorkspace.shared.activateFileViewerSelecting([audioPath])
                        }) {
                            Label("Show Audio in Finder", systemImage: "music.note.list")
                        }
                    }
                }
            }
            
            // Copy File Path (for all items with download location)
            if item.status == .completed || item.status == .downloading {
                Button(action: {
                    NSPasteboard.general.clearContents()
                    // Copy actual file path if available
                    let pathToCopy = item.actualFilePath?.path ?? item.downloadLocation.path
                    NSPasteboard.general.setString(pathToCopy, forType: .string)
                }) {
                    Label("Copy File Path", systemImage: "doc.on.doc.fill")
                }
            }
        }
        .onChange(of: item.errorMessage) { oldValue, newValue in
            // Automatically show format picker if manual selection is required
            if let error = newValue,
               preferences.preferManualFormatSelection && 
               (error.contains("please select manually") || 
                error.contains("manual selection required")) {
                showingFormatError = true
            }
        }
        .sheet(isPresented: $showingFormatPicker) {
            FormatPickerSheet(item: item)
        }
        .sheet(isPresented: $showingFormatError) {
            FormatErrorDialog(
                videoInfo: item.videoInfo,
                availableFormats: item.videoInfo.formats ?? [],
                selectedFormat: Binding(
                    get: { item.format },
                    set: { newFormat in
                        if let format = newFormat {
                            queue.retryWithFormat(item, format: format)
                        }
                    }
                )
            )
        }
    }
}

// Format picker sheet for changing video format
struct FormatPickerSheet: View {
    let item: QueueDownloadTask
    @Environment(\.dismiss) var dismiss
    @State private var selectedFormat: VideoFormat?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Change Format")
                    .font(.headline)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Format list
            ScrollView {
                VStack(spacing: 8) {
                    if let formats = item.videoInfo.formats {
                        ForEach(formats.sorted(by: { ($0.height ?? 0) > ($1.height ?? 0) }), id: \.format_id) { format in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(format.qualityLabel)
                                        .font(.system(size: 13))
                                    Text("\(format.ext) • \(format.vcodec ?? "unknown")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if format.format_id == (selectedFormat?.format_id ?? item.format?.format_id) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(format.format_id == (selectedFormat?.format_id ?? item.format?.format_id) ?
                                          Color.accentColor.opacity(0.1) : Color.clear)
                            )
                            .onTapGesture {
                                selectedFormat = format
                            }
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button("Apply") {
                    if let format = selectedFormat {
                        item.format = format
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFormat == nil)
            }
            .padding()
        }
        .frame(width: 400, height: 500)
        .onAppear {
            selectedFormat = item.format
        }
    }
}
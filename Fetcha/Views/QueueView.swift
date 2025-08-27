import SwiftUI
import Combine

struct QueueView: View {
    @ObservedObject var queue: DownloadQueue
    @State private var showingLocationPicker = false
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with save location
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Download Queue")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.plain)
                    
                    if queue.items.contains(where: { $0.status == .completed || $0.status == .failed }) {
                        Button("Clear Completed") {
                            queue.clearCompleted()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    
                    if queue.items.contains(where: { $0.status == .failed }) {
                        Button("Retry Failed") {
                            queue.retryFailed()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(Color.orange)
                    }
                }
                
                HStack {
                    Image(systemName: "folder")
                        .foregroundColor(.secondary)
                    Text("Save to:")
                        .foregroundColor(.secondary)
                    Text(queue.downloadLocation.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Change") {
                        showingLocationPicker = true
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.tertiaryLabelColor).opacity(0.1))
                .cornerRadius(8)
            }
            .padding()
            
            Divider()
            
            // Queue items
            if queue.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No downloads in queue")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Add videos to start downloading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(queue.items) { item in
                            QueueItemView(item: item, queue: queue)
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: .infinity)
            }
        }
        .fileImporter(
            isPresented: $showingLocationPicker,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    queue.setSaveLocation(url)
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
        .sheet(isPresented: $showingSettings) {
            QueueSettingsView(queue: queue, isPresented: $showingSettings)
        }
    }
}

struct QueueItemView: View {
    @ObservedObject var item: QueueItem
    let queue: DownloadQueue
    @State private var isHovering = false
    @State private var showingFormatPicker = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let thumbnail = item.thumbnail {
                AsyncImage(url: URL(string: thumbnail)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(NSColor.tertiaryLabelColor).opacity(0.2))
                        .overlay(
                            ProgressView()
                                .scaleEffect(0.5)
                        )
                }
                .frame(width: 120, height: 68)
                .cornerRadius(8)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                
                HStack {
                    if item.status == .waiting {
                        Button(action: { showingFormatPicker = true }) {
                            HStack(spacing: 4) {
                                Text(item.formatDescription)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    } else {
                        Text(item.formatDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(item.status.displayText)
                        .font(.caption)
                        .foregroundColor(Color(item.status.color))
                }
                
                if item.status == .downloading {
                    VStack(alignment: .leading, spacing: 2) {
                        ProgressView(value: item.progress, total: 100)
                            .progressViewStyle(.linear)
                        
                        HStack {
                            Text("\(Int(item.progress))%")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            
                            if !item.speed.isEmpty {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(item.speed)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if !item.eta.isEmpty {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text(item.eta)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                if let error = item.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Color.red)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 8) {
                switch item.status {
                case .waiting:
                    Button(action: { queue.removeFromQueue(item) }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                case .downloading:
                    Button(action: { queue.pauseDownload(item) }) {
                        Image(systemName: "pause.circle.fill")
                            .foregroundColor(Color.orange)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { queue.removeFromQueue(item) }) {
                        Image(systemName: "stop.circle.fill")
                            .foregroundColor(Color.red)
                    }
                    .buttonStyle(.plain)
                    
                case .paused:
                    Button(action: { queue.resumeDownload(item) }) {
                        Image(systemName: "play.circle.fill")
                            .foregroundColor(Color.green)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { queue.removeFromQueue(item) }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.green)
                    
                    Button(action: { queue.removeFromQueue(item) }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                case .failed:
                    Button(action: { queue.resumeDownload(item) }) {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(Color.orange)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { queue.removeFromQueue(item) }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .opacity(isHovering ? 1 : 0.6)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isHovering ? Color(NSColor.tertiaryLabelColor).opacity(0.1) : Color(NSColor.tertiaryLabelColor).opacity(0.05))
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .sheet(isPresented: $showingFormatPicker) {
            VStack(spacing: 20) {
                Text("Select Format for \(item.title)")
                    .font(.headline)
                    .lineLimit(2)
                
                FormatSelectionView(
                    videoInfo: item.videoInfo,
                    selectedFormat: Binding(
                        get: { item.format },
                        set: { newFormat in
                            item.format = newFormat
                            showingFormatPicker = false
                        }
                    )
                )
                
                HStack {
                    Button("Cancel") {
                        showingFormatPicker = false
                    }
                    .keyboardShortcut(.escape)
                }
            }
            .padding()
            .frame(width: 500, height: 400)
        }
    }
}
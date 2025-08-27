import SwiftUI
import AppKit

struct VideoDetailsPanel: View {
    let item: QueueDownloadTask?
    @State private var thumbnailImage: NSImage?
    @State private var verboseOutput: String = ""
    @State private var downloadStartTime: Date?
    @State private var totalDownloadTime: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Details")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            if let item = item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Thumbnail
                        if let thumbnail = item.thumbnail {
                            AsyncThumbnailView(url: thumbnail)
                                .frame(height: 180)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        // Title and basic info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(item.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            
                            if let uploader = item.videoInfo.uploader {
                                Label(uploader, systemImage: "person.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if item.videoInfo.duration != nil {
                                Label(item.videoInfo.formattedDuration, systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Format Information
                        GroupBox("Format") {
                            VStack(alignment: .leading, spacing: 6) {
                                if let format = item.selectedFormat {
                                    HStack {
                                        Text("Quality:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(format.qualityLabel)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    
                                    HStack {
                                        Text("Container:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(format.ext.uppercased())
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    
                                    if let vcodec = format.vcodec, vcodec != "none" {
                                        HStack {
                                            Text("Video Codec:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(vcodec)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    if let acodec = format.acodec, acodec != "none" {
                                        HStack {
                                            Text("Audio Codec:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(acodec)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    if let fileSize = format.estimatedFileSize {
                                        HStack {
                                            Text("Est. Size:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                        
                        // Download Statistics
                        if item.status == .downloading || item.status == .completed {
                            GroupBox("Download Stats") {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Status:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(item.statusMessage)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    
                                    if !item.speed.isEmpty {
                                        HStack {
                                            Text("Speed:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(item.speed)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    if !item.eta.isEmpty {
                                        HStack {
                                            Text("ETA:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(item.eta)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    if item.status == .completed && !totalDownloadTime.isEmpty {
                                        HStack {
                                            Text("Total Time:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(totalDownloadTime)
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                    }
                                    
                                    HStack {
                                        Text("Location:")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        Text(item.downloadLocation.path)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .lineLimit(1)
                                            .truncationMode(.middle)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding(.horizontal)
                        }
                        
                        // URL and Actions
                        GroupBox("Source") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.url)
                                    .font(.caption)
                                    .lineLimit(2)
                                    .textSelection(.enabled)
                                
                                HStack {
                                    Button("Copy URL") {
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setString(item.url, forType: .string)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                    
                                    Button("Open in Browser") {
                                        if let url = URL(string: item.url) {
                                            NSWorkspace.shared.open(url)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal)
                        
                        // Verbose Output (collapsible)
                        DisclosureGroup("yt-dlp Output") {
                            ScrollView {
                                Text(verboseOutput.isEmpty ? "No output available" : verboseOutput)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(8)
                                    .background(Color(NSColor.textBackgroundColor))
                                    .cornerRadius(4)
                            }
                            .frame(height: 150)
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            } else {
                // No selection
                VStack {
                    Spacer()
                    Image(systemName: "sidebar.right")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("Select an item to view details")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onChange(of: item) { oldValue, newValue in
            if let item = newValue {
                if item.status == .downloading && downloadStartTime == nil {
                    downloadStartTime = Date()
                } else if item.status == .completed, let startTime = downloadStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    totalDownloadTime = formatElapsedTime(elapsed)
                }
                
                // Capture verbose output
                updateVerboseOutput(for: item)
            }
        }
    }
    
    private func formatElapsedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        if minutes > 0 {
            return "\(minutes)m \(remainingSeconds)s"
        } else {
            return "\(remainingSeconds)s"
        }
    }
    
    private func updateVerboseOutput(for item: QueueDownloadTask) {
        // FUTURE: Phase 5 - Capture actual yt-dlp verbose output
        // Will need to modify YTDLPService to stream output to observers
        // Integration point for real-time process monitoring
        // For now, show formatted summary info
        var output = "URL: \(item.url)\n"
        output += "Title: \(item.title)\n"
        if let format = item.selectedFormat {
            output += "Format: \(format.format_id) - \(format.displayName)\n"
        }
        output += "Status: \(item.statusMessage)\n"
        
        if let error = item.errorMessage {
            output += "\nError: \(error)\n"
        }
        
        verboseOutput = output
    }
}

struct AsyncThumbnailView: View {
    let url: String
    @State private var image: NSImage?
    @State private var currentURL: String = ""
    @State private var loadTask: URLSessionDataTask?
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
        }
        .onAppear {
            loadThumbnail()
        }
        .onChange(of: url) { oldValue, newValue in
            // Cancel any existing load task
            loadTask?.cancel()
            // Reset image and load new thumbnail
            image = nil
            currentURL = newValue
            loadThumbnail()
        }
        .onDisappear {
            // Clean up when view disappears
            loadTask?.cancel()
        }
    }
    
    private func loadThumbnail() {
        // Don't reload if we already have this URL loaded
        guard url != currentURL || image == nil else { return }
        guard let thumbnailURL = URL(string: url) else { return }
        
        currentURL = url
        
        loadTask = URLSession.shared.dataTask(with: thumbnailURL) { data, _, error in
            // Check if task was cancelled
            guard error == nil else { return }
            
            if let data = data, let nsImage = NSImage(data: data) {
                DispatchQueue.main.async {
                    // Only update if this is still the current URL
                    if self.currentURL == self.url {
                        self.image = nsImage
                    }
                }
            }
        }
        loadTask?.resume()
    }
}
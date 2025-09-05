import SwiftUI
import AppKit

struct VideoDetailsPanel: View {
    let item: QueueDownloadTask?
    let historyItem: DownloadHistory.DownloadRecord?
    @State private var thumbnailImage: NSImage?
    @State private var verboseOutput: String = ""
    @State private var downloadStartTime: Date?
    @State private var totalDownloadTime: String = ""
    
    init(item: QueueDownloadTask? = nil, historyItem: DownloadHistory.DownloadRecord? = nil) {
        self.item = item
        self.historyItem = historyItem
    }
    
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
                // Show queue item details
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
                        
                        // Status section
                        VStack(alignment: .leading, spacing: 8) {
                            Label {
                                HStack {
                                    Text(String(describing: item.status).capitalized)
                                        .fontWeight(.medium)
                                    Spacer()
                                    if item.status == .downloading {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                            .progressViewStyle(CircularProgressViewStyle())
                                    }
                                }
                            } icon: {
                                Image(systemName: statusIcon(for: item.status))
                                    .foregroundColor(statusColor(for: item.status))
                            }
                            
                            if item.status == .failed {
                                Text(item.downloadStatus)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .lineLimit(3)
                            }
                            
                            if item.status == .downloading || item.status == .completed {
                                if item.progress > 0 {
                                    HStack {
                                        ProgressView(value: item.progress / 100.0)
                                            .progressViewStyle(LinearProgressViewStyle())
                                        Text("\(Int(item.progress))%")
                                            .font(.caption.monospacedDigit())
                                    }
                                }
                                
                                if !item.speed.isEmpty {
                                    Label(item.speed, systemImage: "speedometer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !item.eta.isEmpty {
                                    Label(item.eta, systemImage: "timer")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .padding(.horizontal)
                        
                        // Download info
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "URL", value: item.url)
                            
                            if let format = item.format {
                                DetailRow(label: "Format", value: "\(format.format_note ?? format.format_id)")
                                DetailRow(label: "Resolution", value: format.resolution ?? "Unknown")
                                if let codec = format.vcodec {
                                    DetailRow(label: "Codec", value: codec)
                                }
                            }
                            
                            DetailRow(label: "Location", value: item.downloadLocation.path)
                            
                            if let actualPath = item.actualFilePath {
                                DetailRow(label: "File", value: actualPath.lastPathComponent)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Actions
                        HStack(spacing: 12) {
                            if item.status == .completed {
                                // Try actualFilePath first, then fallback to finding the file
                                let filePath: URL? = {
                                    if let actualPath = item.actualFilePath {
                                        return actualPath
                                    }
                                    // Fallback: try to find a file with the video title in the download location
                                    let location = item.downloadLocation
                                    if let contents = try? FileManager.default.contentsOfDirectory(at: location, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) {
                                        // Clean the title for better matching
                                        let cleanTitle = item.title
                                            .replacingOccurrences(of: "[", with: "")
                                            .replacingOccurrences(of: "]", with: "")
                                            .replacingOccurrences(of: "(", with: "")
                                            .replacingOccurrences(of: ")", with: "")
                                            .replacingOccurrences(of: "#", with: "")
                                        
                                        let titleWords = cleanTitle.split(separator: " ").prefix(3).map(String.init)
                                        
                                        // Sort by creation date and find the most recent matching file
                                        let sortedFiles = contents.filter { !$0.hasDirectoryPath }.sorted { url1, url2 in
                                            let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                                            let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                                            return date1 > date2
                                        }
                                        
                                        // Look for a file containing title words
                                        return sortedFiles.first { url in
                                            let filename = url.lastPathComponent.lowercased()
                                            let ext = url.pathExtension.lowercased()
                                            return ["mp4", "webm", "mkv", "avi", "mov", "flv", "mp3", "m4a", "opus", "wav", "aac"].contains(ext) &&
                                                   titleWords.contains { word in filename.contains(word.lowercased()) }
                                        } ?? sortedFiles.first { url in
                                            // Fallback to most recent media file
                                            let ext = url.pathExtension.lowercased()
                                            return ["mp4", "webm", "mkv", "avi", "mov", "flv", "mp3", "m4a", "opus", "wav", "aac"].contains(ext)
                                        }
                                    }
                                    return nil
                                }()
                                
                                if let path = filePath {
                                    Button(action: {
                                        let isFile = !path.hasDirectoryPath && FileManager.default.fileExists(atPath: path.path)
                                        DebugLogger.shared.log(
                                            "Show in Finder clicked",
                                            level: .info,
                                            details: "Path: \(path.path), isFile: \(isFile), hasDirectoryPath: \(path.hasDirectoryPath)"
                                        )
                                        if isFile {
                                            NSWorkspace.shared.activateFileViewerSelecting([path])
                                        } else {
                                            // Fallback to parent directory
                                            NSWorkspace.shared.open(path.deletingLastPathComponent())
                                        }
                                    }) {
                                        Label("Show in Finder", systemImage: "folder")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .controlSize(.small)
                                    
                                    Button(action: {
                                        let isFile = !path.hasDirectoryPath && FileManager.default.fileExists(atPath: path.path)
                                        DebugLogger.shared.log(
                                            "Open file clicked",
                                            level: .info,
                                            details: "Path: \(path.path), isFile: \(isFile), hasDirectoryPath: \(path.hasDirectoryPath)"
                                        )
                                        if isFile {
                                            NSWorkspace.shared.open(path)
                                        } else {
                                            // Try to find the file in the directory
                                            if let contents = try? FileManager.default.contentsOfDirectory(at: path.hasDirectoryPath ? path : path.deletingLastPathComponent(), includingPropertiesForKeys: nil) {
                                                if let videoFile = contents.first(where: { !$0.hasDirectoryPath && $0.pathExtension.lowercased() != "part" }) {
                                                    NSWorkspace.shared.open(videoFile)
                                                }
                                            }
                                        }
                                    }) {
                                        Label("Open", systemImage: "play.circle")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .controlSize(.small)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Verbose output section
                        if item.status == .downloading || item.status == .failed {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Output")
                                    .font(.headline)
                                
                                ScrollView {
                                    Text(item.downloadStatus.isEmpty ? "No output available" : item.downloadStatus)
                                        .font(.system(size: 11, design: .monospaced))
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(8)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(4)
                                }
                                .frame(height: 150)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            } else if let historyItem = historyItem {
                // Show history item details
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Thumbnail
                        if let thumbnail = historyItem.thumbnail {
                            AsyncThumbnailView(url: thumbnail)
                                .frame(height: 180)
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        // Title and basic info
                        VStack(alignment: .leading, spacing: 8) {
                            Text(historyItem.title)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .lineLimit(2)
                            
                            if let uploader = historyItem.uploader {
                                Label(uploader, systemImage: "person.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Label("Completed", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            
                            if let duration = historyItem.duration {
                                Label(formatDuration(Int(duration)), systemImage: "clock")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Download info
                        VStack(alignment: .leading, spacing: 8) {
                            DetailRow(label: "URL", value: historyItem.url)
                            DetailRow(label: "Downloaded", value: formatDate(historyItem.timestamp))
                            DetailRow(label: "Location", value: historyItem.downloadPath)
                            
                            // Show actual filename if available
                            if !historyItem.filename.isEmpty {
                                DetailRow(label: "File", value: historyItem.filename)
                            }
                            
                            if let fileSize = historyItem.fileSize {
                                DetailRow(label: "Size", value: formatFileSize(fileSize))
                            }
                        }
                        .padding(.horizontal)
                        
                        // Actions
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Button(action: {
                                    // Use the DownloadHistory method to find the actual file
                                    if let actualFileURL = DownloadHistory.shared.findActualFile(for: historyItem) {
                                        NSWorkspace.shared.activateFileViewerSelecting([actualFileURL])
                                        DebugLogger.shared.log("Showing file in Finder", level: .info, details: actualFileURL.lastPathComponent)
                                    } else {
                                        // Fall back to directory
                                        let url = URL(fileURLWithPath: historyItem.resolvedFilePath)
                                        if FileManager.default.fileExists(atPath: url.path) {
                                            NSWorkspace.shared.open(url)
                                        } else {
                                            NSWorkspace.shared.open(url.deletingLastPathComponent())
                                        }
                                    }
                                }) {
                                    Label("Show in Finder", systemImage: "folder")
                                        .frame(maxWidth: .infinity)
                                }
                                .controlSize(.small)
                                
                                Button(action: {
                                    // Use the DownloadHistory method to find the actual file
                                    if let actualFileURL = DownloadHistory.shared.findActualFile(for: historyItem) {
                                        NSWorkspace.shared.open(actualFileURL)
                                        DebugLogger.shared.log("Opening file", level: .info, details: actualFileURL.lastPathComponent)
                                    } else {
                                        DebugLogger.shared.log(
                                            "File not found: \(historyItem.title)",
                                            level: .warning,
                                            details: "Path: \(historyItem.resolvedFilePath)"
                                        )
                                    }
                                }) {
                                    Label("Open", systemImage: "play.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .controlSize(.small)
                            }
                            
                            HStack(spacing: 12) {
                                // Open in Browser button
                                Button(action: {
                                    if let url = URL(string: historyItem.url) {
                                        NSWorkspace.shared.open(url)
                                    }
                                }) {
                                    Label("Open in Browser", systemImage: "safari")
                                        .frame(maxWidth: .infinity)
                                }
                                .controlSize(.small)
                                
                                // Copy Source URL button
                                Button(action: {
                                    NSPasteboard.general.clearContents()
                                    NSPasteboard.general.setString(historyItem.url, forType: .string)
                                }) {
                                    Label("Copy Source", systemImage: "doc.on.doc")
                                        .frame(maxWidth: .infinity)
                                }
                                .controlSize(.small)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            } else {
                // No selection
                ContentUnavailableView {
                    Label("No Selection", systemImage: "sidebar.right")
                } description: {
                    Text("Select an item to view details")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // Helper functions
    func statusIcon(for status: DownloadStatus) -> String {
        switch status {
        case .waiting: return "clock"
        case .downloading: return "arrow.down.circle"
        case .paused: return "pause.circle"
        case .completed: return "checkmark.circle"
        case .failed: return "xmark.circle"
        }
    }
    
    func statusColor(for status: DownloadStatus) -> Color {
        switch status {
        case .waiting: return .secondary
        case .downloading: return .blue
        case .paused: return .orange
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .trailing)
            
            Text(value)
                .font(.caption)
                .lineLimit(2)
                .textSelection(.enabled)
            
            Spacer()
        }
    }
}

struct AsyncThumbnailView: View {
    let url: String
    @State private var image: NSImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Rectangle()
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    )
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    func loadImage() {
        // Check if it's a local file path
        if url.hasPrefix("/") {
            // Local file path
            if let nsImage = NSImage(contentsOfFile: url) {
                DispatchQueue.main.async {
                    self.image = nsImage
                }
            }
        } else if let imageURL = URL(string: url) {
            // Remote URL
            URLSession.shared.dataTask(with: imageURL) { data, _, _ in
                if let data = data, let nsImage = NSImage(data: data) {
                    DispatchQueue.main.async {
                        self.image = nsImage
                    }
                }
            }.resume()
        }
    }
}
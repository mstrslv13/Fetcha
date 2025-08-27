import SwiftUI

struct PlaylistConfirmationView: View {
    let playlistInfo: PlaylistInfo
    let onConfirm: (PlaylistAction) -> Void
    let onCancel: () -> Void
    
    @State private var selectedAction: PlaylistAction = .downloadAll
    @State private var startIndex: Int = 1
    @State private var endIndex: Int = 0
    @State private var skipExisting: Bool = true
    @State private var reverseOrder: Bool = false
    @StateObject private var history = DownloadHistory.shared
    
    enum PlaylistAction {
        case downloadAll
        case downloadRange(start: Int, end: Int)
        case downloadSingle
        case cancel
    }
    
    struct PlaylistInfo {
        let title: String
        let uploader: String?
        let videoCount: Int
        let videos: [VideoInfo]
        let playlistId: String?
    }
    
    var existingCount: Int {
        playlistInfo.videos.filter { video in
            if let videoId = extractVideoId(from: video.webpage_url) {
                return history.hasDownloaded(videoId: videoId)
            }
            return false
        }.count
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "list.and.film")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                
                Text("Playlist Detected")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(playlistInfo.title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                if let uploader = playlistInfo.uploader {
                    Text("by \(uploader)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Playlist info
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("\(playlistInfo.videoCount) videos", systemImage: "video.fill")
                    Spacer()
                    if existingCount > 0 {
                        Label("\(existingCount) already downloaded", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                .font(.caption)
                
                // Action selection
                VStack(alignment: .leading, spacing: 8) {
                    RadioButton(
                        title: "Download all videos",
                        subtitle: skipExisting && existingCount > 0 ? 
                            "Will download \(playlistInfo.videoCount - existingCount) new videos" : nil,
                        isSelected: selectedAction.isDownloadAll
                    ) {
                        selectedAction = .downloadAll
                    }
                    
                    RadioButton(
                        title: "Download specific range",
                        isSelected: selectedAction.isDownloadRange
                    ) {
                        selectedAction = .downloadRange(start: startIndex, end: endIndex)
                    }
                    
                    if selectedAction.isDownloadRange {
                        HStack {
                            Text("From:")
                            TextField("Start", value: $startIndex, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            
                            Text("To:")
                            TextField("End", value: $endIndex, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 60)
                            
                            Text("(0 = all)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 24)
                    }
                    
                    RadioButton(
                        title: "Download first video only",
                        isSelected: selectedAction.isDownloadSingle
                    ) {
                        selectedAction = .downloadSingle
                    }
                }
                
                Divider()
                
                // Options
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Skip already downloaded videos", isOn: $skipExisting)
                        .disabled(existingCount == 0)
                    
                    Toggle("Download in reverse order (newest first)", isOn: $reverseOrder)
                        .disabled(selectedAction.isDownloadSingle)
                }
                .font(.caption)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            // Remember preference
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.secondary)
                Text("You can change the default behavior in Preferences")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            // Action buttons
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Add to Queue") {
                    var action = selectedAction
                    if case .downloadRange = selectedAction {
                        action = .downloadRange(start: startIndex, end: endIndex)
                    }
                    onConfirm(action)
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500)
    }
    
    private func extractVideoId(from url: String) -> String? {
        // Extract video ID from URL
        if let regex = try? NSRegularExpression(pattern: "v=([a-zA-Z0-9_-]{11})"),
           let match = regex.firstMatch(in: url, range: NSRange(url.startIndex..., in: url)),
           let range = Range(match.range(at: 1), in: url) {
            return String(url[range])
        }
        return nil
    }
}

struct RadioButton: View {
    let title: String
    var subtitle: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.system(size: 14))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

extension PlaylistConfirmationView.PlaylistAction {
    var isDownloadAll: Bool {
        if case .downloadAll = self { return true }
        return false
    }
    
    var isDownloadRange: Bool {
        if case .downloadRange = self { return true }
        return false
    }
    
    var isDownloadSingle: Bool {
        if case .downloadSingle = self { return true }
        return false
    }
    
    var isCancel: Bool {
        if case .cancel = self { return true }
        return false
    }
}
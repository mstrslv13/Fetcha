import SwiftUI
import UniformTypeIdentifiers
import AppKit
import Combine

struct ContentView: View {
    @State private var urlString = ""
    @State private var statusMessage = "Paste a video URL to start downloading"
    @State private var isLoading = false
    @State private var videoInfo: VideoInfo?
    @State private var selectedFormat: VideoFormat?
    @State private var showingDebugView = false
    @State private var showingPreferences = false
    @State private var lastClipboard = ""
    @State private var selectedQueueItem: QueueDownloadTask?
    @State private var showingPlaylistConfirmation = false
    @State private var detectedPlaylistInfo: PlaylistConfirmationView.PlaylistInfo?
    @State private var showDebugPanel = false
    @State private var showDetailsPanel = true
    @StateObject private var downloadQueue = DownloadQueue()
    @StateObject private var preferences = AppPreferences.shared
    @StateObject private var downloadHistory = DownloadHistory.shared
    @StateObject private var debugLogger = PersistentDebugLogger.shared
    @State private var updateCheckTimer: Timer?
    
    // Window references to ensure single instances
    static var preferencesWindow: NSWindow?
    static var debugWindow: NSWindow?
    
    private let ytdlpService = YTDLPService()
    private let pasteboardTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        HStack(spacing: 0) {
            // History panel on the left (animated)
            if showDebugPanel {
                DebugHistoryPanel()
                    .frame(width: 300)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                
                Divider()
            }
            
            // Main column with URL input and queue
            VStack(spacing: 0) {
                // Top bar with title and preferences
                HStack {
                    Text("Fetcha")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Overall queue progress
                    if !downloadQueue.items.isEmpty {
                        QueueProgressIndicator(queue: downloadQueue)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // History Panel Toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showDebugPanel.toggle()
                            }
                        }) {
                            Image(systemName: showDebugPanel ? "sidebar.left.filled" : "sidebar.left")
                                .foregroundColor(showDebugPanel ? .accentColor : Color(NSColor.labelColor))
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help("Toggle History")
                        
                        // Details Panel Toggle
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showDetailsPanel.toggle()
                            }
                        }) {
                            Image(systemName: showDetailsPanel ? "sidebar.right.filled" : "sidebar.right")
                                .foregroundColor(showDetailsPanel ? .accentColor : Color(NSColor.labelColor))
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help("Toggle Details")
                        
                        Divider()
                            .frame(height: 20)
                        
                        // Debug Console
                        if preferences.showDebugConsole {
                            Button(action: {
                                showingDebugView = true
                            }) {
                                Image(systemName: "terminal")
                                    .foregroundColor(Color(NSColor.labelColor))
                                    .font(.title2)
                            }
                            .buttonStyle(.plain)
                            .help("Debug Console")
                        }
                        
                        // About
                        Button(action: {
                            showAboutWindow()
                        }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(Color(NSColor.labelColor))
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help("About Fetcha")
                        
                        // Preferences
                        Button(action: {
                            showingPreferences = true
                        }) {
                            Image(systemName: "gearshape")
                                .foregroundColor(Color(NSColor.labelColor))
                                .font(.title2)
                        }
                        .buttonStyle(.plain)
                        .help("Preferences")
                    }
                }
                .padding()
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // URL input field
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        // Search icon
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                            .padding(.leading, 8)
                        
                        TextField("Search or paste URL...", text: $urlString)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14))
                            .onSubmit {
                                handleURLSubmit()
                            }
                            .onChange(of: urlString) { oldValue, newValue in
                                if preferences.autoAddToQueue && isValidURL(newValue) {
                                    handleURLSubmit()
                                }
                            }
                        
                        // Clear button
                        if !urlString.isEmpty {
                            Button(action: {
                                urlString = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        Divider()
                            .frame(height: 20)
                        
                        Button(action: {
                            pasteAndProcess()
                        }) {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .help("Paste from clipboard")
                        
                        if !preferences.autoAddToQueue {
                            Button("Add") {
                                handleURLSubmit()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(urlString.isEmpty || isLoading)
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Status message
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Download queue with drag & drop support
                EnhancedQueueView(
                    queue: downloadQueue,
                    selectedItem: $selectedQueueItem
                )
            }
            .frame(minWidth: 500)
            
            // Details panel on the right (animated)
            if showDetailsPanel {
                Divider()
                
                VideoDetailsPanel(item: selectedQueueItem)
                    .frame(width: 350)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .frame(minWidth: calculateMinWidth(), minHeight: 600)
        .animation(.easeInOut(duration: 0.25), value: showDebugPanel)
        .animation(.easeInOut(duration: 0.25), value: showDetailsPanel)
        .onReceive(pasteboardTimer) { _ in
            checkClipboardForURL()
        }
        .onChange(of: showingDebugView) { oldValue, newValue in
            if newValue {
                openDebugWindow()
                showingDebugView = false
            }
        }
        .onChange(of: showingPreferences) { oldValue, newValue in
            if newValue {
                openPreferencesWindow()
                showingPreferences = false
            }
        }
        .onAppear {
            statusMessage = preferences.autoAddToQueue ? 
                "Auto-queue enabled: Paste any URL to start downloading" : 
                "Paste a video URL to get started"
            
            // Check for updates on launch if enabled
            if preferences.autoCheckUpdates {
                checkForUpdatesIfNeeded()
            }
            
            // Set up daily update check timer
            updateCheckTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
                if preferences.autoCheckUpdates {
                    checkForUpdatesIfNeeded()
                }
            }
        }
        .onDisappear {
            updateCheckTimer?.invalidate()
            updateCheckTimer = nil
        }
        .sheet(isPresented: $showingPlaylistConfirmation) {
            if let playlistInfo = detectedPlaylistInfo {
                PlaylistConfirmationView(
                    playlistInfo: playlistInfo,
                    onConfirm: { action in
                        showingPlaylistConfirmation = false
                        handlePlaylistAction(action, url: urlString, playlistInfo: playlistInfo)
                    },
                    onCancel: {
                        showingPlaylistConfirmation = false
                        isLoading = false
                        statusMessage = "Playlist cancelled"
                        urlString = ""
                    }
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func calculateMinWidth() -> CGFloat {
        var width: CGFloat = 500 // Base width
        if showDebugPanel {
            width += 300 // History panel width
        }
        if showDetailsPanel {
            width += 350 // Details panel width
        }
        return width
    }
    
    private func handlePlaylistAction(_ action: PlaylistConfirmationView.PlaylistAction, url: String, playlistInfo: PlaylistConfirmationView.PlaylistInfo) {
        switch action {
        case .downloadAll:
            addPlaylistToQueue(url: url, downloadAll: true)
        case .downloadRange(let start, let end):
            addPlaylistToQueue(url: url, downloadAll: true, range: (start: start, end: end))
        case .downloadSingle:
            addPlaylistToQueue(url: url, downloadAll: false)
        case .cancel:
            statusMessage = "Cancelled"
            urlString = ""
        }
    }
    
    private func checkClipboardForURL() {
        guard preferences.autoAddToQueue else { return }
        
        if let clipboard = NSPasteboard.general.string(forType: .string),
           clipboard != lastClipboard,
           isValidURL(clipboard) {
            lastClipboard = clipboard
            let url = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !downloadQueue.items.contains(where: { $0.url == url }) {
                urlString = ""
                if preferences.skipMetadataFetch {
                    quickAddToQueueWithURL(url)
                } else {
                    fetchAndAutoAddWithURL(url)
                }
            }
        }
    }
    
    private func isValidURL(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let patterns = [
            "^https?://",
            "^(www\\.)?youtube\\.com",
            "^(www\\.)?youtu\\.be",
            "^(www\\.)?vimeo\\.com",
            "^(www\\.)?twitter\\.com",
            "^(www\\.)?x\\.com"
        ]
        
        return patterns.contains { pattern in
            trimmed.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
        }
    }
    
    private func handleURLSubmit() {
        guard !urlString.isEmpty else { return }
        
        let url = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isValidURL(url) else {
            statusMessage = "Invalid URL format"
            return
        }
        
        if downloadQueue.items.contains(where: { $0.url == url }) {
            statusMessage = "URL already in queue"
            return
        }
        
        // INSTANT queue addition - no network calls!
        let placeholderInfo = VideoInfo(
            title: "Loading...",
            uploader: nil,
            duration: nil,
            webpage_url: url,
            thumbnail: nil,
            formats: nil,
            description: nil,
            upload_date: nil,
            timestamp: nil,
            view_count: nil,
            like_count: nil,
            channel_id: nil,
            uploader_id: nil,
            uploader_url: nil
        )
        
        downloadQueue.addToQueue(url: url, format: nil, videoInfo: placeholderInfo)
        statusMessage = "Added to queue ✓"
        urlString = ""
        
        // Fetch metadata in background (optional - for UI updates only)
        Task {
            if let info = try? await ytdlpService.fetchMetadata(for: url) {
                // FUTURE: Update the queue item with real metadata
                // This would update the "Loading..." title with the real title
            }
        }
    }
    
    private func handlePlaylistURL(url: String, videoCount: Int?) {
        statusMessage = "Playlist detected (\(videoCount ?? 0) videos)"
        
        // Check user preference for playlist handling
        switch preferences.playlistHandling {
        case "ask":
            // Show confirmation dialog
            isLoading = true
            Task {
                do {
                    let playlistInfo = try await ytdlpService.fetchPlaylistInfo(
                        urlString: url,
                        limit: min(preferences.playlistLimit, 100)
                    )
                    await MainActor.run {
                        self.detectedPlaylistInfo = playlistInfo
                        self.showingPlaylistConfirmation = true
                        self.isLoading = false
                    }
                } catch {
                    await MainActor.run {
                        self.isLoading = false
                        self.statusMessage = "Failed to fetch playlist: \(error.localizedDescription)"
                    }
                }
            }
            
        case "all":
            // Automatically download all videos
            addPlaylistToQueue(url: url, downloadAll: true)
            
        case "single":
            // Just download the first video
            addPlaylistToQueue(url: url, downloadAll: false)
            
        default:
            statusMessage = "Unknown playlist handling preference"
        }
    }
    
    private func addPlaylistToQueue(url: String, downloadAll: Bool, range: (start: Int, end: Int)? = nil) {
        isLoading = true
        statusMessage = downloadAll ? "Adding playlist to queue..." : "Adding first video..."
        
        Task {
            do {
                let playlistInfo = try await ytdlpService.fetchPlaylistInfo(
                    urlString: url,
                    limit: downloadAll ? preferences.playlistLimit : 1
                )
                
                await MainActor.run {
                    var videosToAdd = playlistInfo.videos
                    
                    // Apply range if specified
                    if let range = range {
                        let startIdx = max(0, range.start - 1)
                        let endIdx = range.end > 0 ? min(range.end, videosToAdd.count) : videosToAdd.count
                        videosToAdd = Array(videosToAdd[startIdx..<endIdx])
                    }
                    
                    // Apply reverse order if needed
                    if preferences.reversePlaylist {
                        videosToAdd.reverse()
                    }
                    
                    // Filter out duplicates if needed
                    if preferences.skipDuplicates {
                        videosToAdd = videosToAdd.filter { video in
                            !downloadHistory.hasDownloaded(url: video.webpage_url)
                        }
                    }
                    
                    // Add videos to queue
                    var addedCount = 0
                    for video in videosToAdd {
                        // Fetch full metadata for each video
                        Task {
                            do {
                                let fullInfo = try await ytdlpService.fetchMetadata(for: video.webpage_url)
                                await MainActor.run {
                                    downloadQueue.addToQueue(
                                        url: video.webpage_url,
                                        format: fullInfo.bestFormat,
                                        videoInfo: fullInfo
                                    )
                                }
                            } catch {
                                print("Failed to fetch metadata for \(video.title): \(error)")
                            }
                        }
                        addedCount += 1
                    }
                    
                    statusMessage = "Added \(addedCount) videos to queue"
                    urlString = ""
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.statusMessage = "Failed to add playlist: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func fetchAndAutoAddWithURL(_ url: String) {
        isLoading = true
        statusMessage = "Auto-adding from clipboard..."
        
        Task {
            do {
                let info = try await ytdlpService.fetchMetadata(for: url)
                await MainActor.run {
                    downloadQueue.addToQueue(url: url, format: info.bestFormat, videoInfo: info)
                    statusMessage = "Auto-added: \(info.title)"
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    statusMessage = "Failed to auto-add: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func quickAddToQueueWithURL(_ url: String) {
        let placeholderInfo = VideoInfo(
            title: "Loading...",
            uploader: nil,
            duration: nil,
            webpage_url: url,
            thumbnail: nil,
            formats: nil,
            description: nil,
            upload_date: nil,
            timestamp: nil,
            view_count: nil,
            like_count: nil,
            channel_id: nil,
            uploader_id: nil,
            uploader_url: nil
        )
        
        downloadQueue.addToQueue(url: url, format: nil, videoInfo: placeholderInfo)
        statusMessage = "Quick-added to queue (metadata loading...)"
        
        Task {
            if let item = downloadQueue.items.first(where: { $0.url == url }) {
                if let info = try? await ytdlpService.fetchMetadata(for: url) {
                    await MainActor.run {
                        // FUTURE: Phase 5 - Update queue item with fetched metadata
                        // This would need to be implemented in DownloadQueue
                        // Would update the placeholder "Loading..." with real title
                        // Integration point for background metadata updates
                    }
                }
            }
        }
    }
    
    private func pasteAndProcess() {
        if let clipboard = NSPasteboard.general.string(forType: .string) {
            urlString = clipboard.trimmingCharacters(in: .whitespacesAndNewlines)
            handleURLSubmit()
        } else {
            statusMessage = "No URL found in clipboard"
        }
    }
    
    private func addToQueue() {
        guard let info = videoInfo else { return }
        let format = selectedFormat ?? info.bestFormat
        
        downloadQueue.addToQueue(url: info.webpage_url, format: format, videoInfo: info)
        statusMessage = "Added to queue: \(info.title)"
        urlString = ""
        videoInfo = nil
        selectedFormat = nil
    }
    
    private func openDebugWindow() {
        // Check if window already exists
        if let existingWindow = ContentView.debugWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let debugView = DebugView()
        let hostingController = NSHostingController(rootView: debugView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Debug Console"
        window.setContentSize(NSSize(width: 600, height: 400))
        window.styleMask = [.titled, .closable, .resizable, .miniaturizable]
        
        // Store reference
        ContentView.debugWindow = window
        
        // Clear reference when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            ContentView.debugWindow = nil
        }
        
        window.makeKeyAndOrderFront(nil)
    }
    
    private func openPreferencesWindow() {
        // Check if window already exists
        if let existingWindow = ContentView.preferencesWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }
        
        let prefsView = PreferencesView()
        let hostingController = NSHostingController(rootView: prefsView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.setContentSize(NSSize(width: 850, height: 550))
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        
        // Store reference
        ContentView.preferencesWindow = window
        
        // Clear reference when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { _ in
            ContentView.preferencesWindow = nil
        }
        
        window.makeKeyAndOrderFront(nil)
    }
    
    private func showAboutWindow() {
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About Fetcha"
        window.styleMask = [.titled, .closable]
        window.isMovableByWindowBackground = true
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
    
    private func checkForUpdatesIfNeeded() {
        // Check if it's been at least 24 hours since last check
        let hoursSinceLastCheck = Date().timeIntervalSince(preferences.lastUpdateCheck) / 3600
        if hoursSinceLastCheck >= 24 {
            Task {
                await performUpdateCheck()
            }
        }
    }
    
    private func performUpdateCheck() async {
        // This performs a silent background check
        var hasUpdates = false
        var ytdlpLatest: String?
        var ffmpegLatest: String?
        
        // Check yt-dlp
        if let currentVersion = try? await ytdlpService.getYTDLPVersion(),
           let latestVersion = try? await ytdlpService.getLatestYTDLPVersion(),
           currentVersion != latestVersion && latestVersion != "Unknown" {
            hasUpdates = true
            ytdlpLatest = latestVersion
        }
        
        // Check ffmpeg
        if let currentVersion = try? await ytdlpService.getFFmpegVersion(),
           let latestVersion = try? await ytdlpService.getLatestFFmpegVersion(),
           currentVersion != latestVersion && latestVersion != "Unknown" {
            hasUpdates = true
            ffmpegLatest = latestVersion
        }
        
        await MainActor.run {
            preferences.lastUpdateCheck = Date()
            
            if hasUpdates {
                if preferences.autoInstallUpdates {
                    // Auto-install updates silently
                    Task {
                        if ytdlpLatest != nil {
                            _ = try? await ytdlpService.upgradeYTDLP()
                        }
                        if ffmpegLatest != nil {
                            _ = try? await ytdlpService.upgradeFFmpeg()
                        }
                    }
                } else if preferences.showUpdateNotifications {
                    // Show notification
                    var message = "Updates available: "
                    if let version = ytdlpLatest {
                        message += "yt-dlp (\(version))"
                    }
                    if let version = ffmpegLatest {
                        if ytdlpLatest != nil { message += ", " }
                        message += "ffmpeg (\(version))"
                    }
                    statusMessage = message
                }
            }
        }
    }
}

// Queue progress indicator showing overall progress
struct QueueProgressIndicator: View {
    @ObservedObject var queue: DownloadQueue
    
    var completedCount: Int {
        queue.items.filter { $0.status == .completed }.count
    }
    
    var totalCount: Int {
        queue.items.count
    }
    
    var downloadingCount: Int {
        queue.items.filter { $0.status == .downloading }.count
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if totalCount > 0 {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(completedCount) / CGFloat(totalCount), height: 4)
                    }
                }
                .frame(width: 100, height: 4)
                
                // Stats
                HStack(spacing: 4) {
                    if downloadingCount > 0 {
                        Label("\(downloadingCount)", systemImage: "arrow.down.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    Label("\(completedCount)/\(totalCount)", systemImage: "checkmark.circle")
                        .foregroundColor(completedCount == totalCount ? .green : .secondary)
                }
                .font(.caption)
            }
        }
    }
}
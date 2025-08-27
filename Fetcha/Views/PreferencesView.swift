import SwiftUI

struct PreferencesView: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var selectedTab = "general"
    @State private var showingFolderPicker = false
    @State private var namingTemplateExample = ""
    
    var body: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            // Sidebar
            List(selection: $selectedTab) {
                Label("General", systemImage: "gear")
                    .tag("general")
                
                Label("Downloads", systemImage: "arrow.down.circle")
                    .tag("downloads")
                
                Label("Naming", systemImage: "textformat")
                    .tag("naming")
                
                Label("Playlists", systemImage: "list.and.film")
                    .tag("playlists")
                
                Label("Advanced", systemImage: "wrench.and.screwdriver")
                    .tag("advanced")
                
                Label("Maintenance", systemImage: "gearshape.2")
                    .tag("maintenance")
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 220)
        } detail: {
            // Content area
            ScrollView {
                Group {
                    switch selectedTab {
                    case "general":
                        GeneralTab()
                    case "downloads":
                        DownloadsTab()
                    case "naming":
                        NamingTab()
                    case "playlists":
                        PlaylistTab()
                    case "advanced":
                        AdvancedTab()
                    case "maintenance":
                        MaintenanceTab()
                    default:
                        GeneralTab()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
        .navigationSplitViewStyle(.balanced)
        .frame(width: 850, height: 550)
    }
}

struct GeneralTab: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var showingFolderPicker = false
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Download Location:")
                        TextField("Download path", text: $preferences.downloadPath, prompt: Text(preferences.resolvedDownloadPath))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Choose...") {
                            showingFolderPicker = true
                        }
                    }
                    
                    // Show the resolved path if different
                    if !preferences.downloadPath.isEmpty && preferences.downloadPath != preferences.resolvedDownloadPath {
                        HStack {
                            Image(systemName: "folder")
                                .foregroundColor(.secondary)
                            Text(preferences.resolvedDownloadPath)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Picker("Default Quality:", selection: $preferences.defaultVideoQuality) {
                    ForEach(Array(preferences.qualityOptions.keys.sorted()), id: \.self) { key in
                        Text(preferences.qualityOptions[key] ?? key)
                            .tag(key)
                    }
                }
                
                Toggle("Auto-add URLs to queue", isOn: $preferences.autoAddToQueue)
                    .help("Automatically add URLs to the download queue when pasted")
                
                Toggle("Skip metadata fetch for auto-added URLs", isOn: $preferences.skipMetadataFetch)
                    .help("Immediately queue URLs without fetching metadata first")
                    .disabled(!preferences.autoAddToQueue)
                
                Toggle("Single-pane mode", isOn: $preferences.singlePaneMode)
                    .help("Show queue in main window instead of separate window")
                
                Toggle("Show debug console", isOn: $preferences.showDebugConsole)
                    .help("Display debug information during downloads")
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case .success(let url):
                // Request access to the selected folder
                let gotAccess = url.startAccessingSecurityScopedResource()
                preferences.downloadPath = url.path
                
                // Also update the download queue
                if let queue = NSApplication.shared.windows.first?.contentViewController?.view.subviews.first {
                    // The download queue should pick this up via the preference observer
                }
                
                if gotAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
    }
}

struct DownloadsTab: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var showingAudioFolderPicker = false
    @State private var showingVideoOnlyFolderPicker = false
    
    var body: some View {
        Form {
            Section("Download Locations") {
                Toggle("Use separate locations for different file types", isOn: $preferences.useSeparateLocations)
                    .help("Save audio, video-only, and merged files to different folders")
                
                if preferences.useSeparateLocations {
                    VStack(spacing: 12) {
                        // Audio-only location
                        HStack {
                            Image(systemName: "music.note")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text("Audio Files:")
                                .frame(width: 100, alignment: .trailing)
                            TextField("Audio path", text: $preferences.audioDownloadPath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Choose...") {
                                showingAudioFolderPicker = true
                            }
                        }
                        
                        // Video-only location
                        HStack {
                            Image(systemName: "film")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            Text("Video-only:")
                                .frame(width: 100, alignment: .trailing)
                            TextField("Video-only path", text: $preferences.videoOnlyDownloadPath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Button("Choose...") {
                                showingVideoOnlyFolderPicker = true
                            }
                        }
                        
                        Text("Merged files will use the main download location")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            
            Divider()
            
            Section("Download Options") {
                Toggle("Download audio only", isOn: $preferences.downloadAudio)
                
                if preferences.downloadAudio {
                    Picker("Audio Format:", selection: $preferences.audioFormat) {
                        ForEach(Array(preferences.audioFormatOptions.keys.sorted()), id: \.self) { key in
                            Text(preferences.audioFormatOptions[key] ?? key)
                                .tag(key)
                        }
                    }
                }
                
                HStack {
                    Text("Concurrent Downloads:")
                    Stepper(value: $preferences.maxConcurrentDownloads, in: 1...10) {
                        Text("\(preferences.maxConcurrentDownloads)")
                    }
                }
                
                HStack {
                    Text("Rate Limit (KB/s):")
                    TextField("0 = unlimited", value: $preferences.rateLimitKbps, format: .number)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 100)
                    Text("(0 = unlimited)")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Retry Attempts:")
                    Stepper(value: $preferences.retryAttempts, in: 0...10) {
                        Text("\(preferences.retryAttempts)")
                    }
                }
            }
            
        }
        .padding()
        .fileImporter(
            isPresented: $showingAudioFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                let gotAccess = url.startAccessingSecurityScopedResource()
                preferences.audioDownloadPath = url.path
                if gotAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
        .fileImporter(
            isPresented: $showingVideoOnlyFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            if case .success(let url) = result {
                let gotAccess = url.startAccessingSecurityScopedResource()
                preferences.videoOnlyDownloadPath = url.path
                if gotAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }
        }
    }
}

struct NamingTab: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var selectedPreset = ""
    @State private var templatePreview = ""
    @State private var cursorPosition: Int? = nil
    
    var body: some View {
        Form {
            Section("File Naming") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Naming Template:")
                        .font(.headline)
                    
                    HStack {
                        TextField("%(title)s.%(ext)s", text: $preferences.namingTemplate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: preferences.namingTemplate) { oldValue, newValue in
                                updatePreview()
                            }
                            .id("namingField")
                        
                        // Clear button
                        if !preferences.namingTemplate.isEmpty {
                            Button(action: {
                                preferences.namingTemplate = "%(title)s.%(ext)s"
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    Picker("Presets:", selection: $selectedPreset) {
                        Text("Custom").tag("")
                        Divider()
                        ForEach(Array(preferences.namingTemplatePresets.keys), id: \.self) { key in
                            Text(preferences.namingTemplatePresets[key] ?? key)
                                .tag(key)
                        }
                    }
                    .onChange(of: selectedPreset) { oldValue, newValue in
                        if !newValue.isEmpty {
                            preferences.namingTemplate = newValue
                        }
                    }
                    
                    if !templatePreview.isEmpty {
                        GroupBox("Preview") {
                            Text(templatePreview)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            
            Section("Folder Organization") {
                Toggle("Create subfolders", isOn: $preferences.createSubfolders)
                
                if preferences.createSubfolders {
                    HStack {
                        Text("Subfolder Template:")
                        TextField("%(uploader)s", text: $preferences.subfolderTemplate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
            
            Section("Template Variables (Click to insert)") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        TemplateHelpRow(variable: "%(title)s", description: "Video title", template: $preferences.namingTemplate)
                        TemplateHelpRow(variable: "%(uploader)s", description: "Channel/uploader name", template: $preferences.namingTemplate)
                        TemplateHelpRow(variable: "%(upload_date)s", description: "Upload date (YYYYMMDD)", template: $preferences.namingTemplate)
                        TemplateHelpRow(variable: "%(ext)s", description: "File extension", template: $preferences.namingTemplate)
                        TemplateHelpRow(variable: "%(id)s", description: "Video ID", template: $preferences.namingTemplate)
                        TemplateHelpRow(variable: "%(playlist)s", description: "Playlist name", template: $preferences.namingTemplate)
                        TemplateHelpRow(variable: "%(playlist_index)s", description: "Position in playlist", template: $preferences.namingTemplate)
                        TemplateHelpRow(variable: "%(resolution)s", description: "Video resolution", template: $preferences.namingTemplate)
                    }
                    .padding(.vertical, 5)
                }
                .frame(maxHeight: 150)
            }
        }
        .padding()
        .onAppear {
            updatePreview()
        }
    }
    
    func updatePreview() {
        var preview = preferences.namingTemplate
        preview = preview.replacingOccurrences(of: "%(title)s", with: "Example Video Title")
        preview = preview.replacingOccurrences(of: "%(uploader)s", with: "Channel Name")
        preview = preview.replacingOccurrences(of: "%(upload_date)s", with: "20250123")
        preview = preview.replacingOccurrences(of: "%(ext)s", with: "mp4")
        preview = preview.replacingOccurrences(of: "%(id)s", with: "dQw4w9WgXcQ")
        preview = preview.replacingOccurrences(of: "%(playlist)s", with: "My Playlist")
        preview = preview.replacingOccurrences(of: "%(playlist_index)s", with: "01")
        preview = preview.replacingOccurrences(of: "%(resolution)s", with: "1080p")
        templatePreview = preview
    }
}

struct TemplateHelpRow: View {
    let variable: String
    let description: String
    @Binding var template: String
    
    var body: some View {
        Button(action: {
            // Insert variable at current position or append
            if !template.contains(variable) {
                // Remove extension if adding new variable
                if template.hasSuffix(".%(ext)s") {
                    let base = String(template.dropLast(9))
                    template = base + "-" + variable + ".%(ext)s"
                } else {
                    template += variable
                }
            }
        }) {
            HStack {
                Text(variable)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.accentColor)
                    .frame(width: 150, alignment: .leading)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Image(systemName: "plus.circle")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .opacity(0.6)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            if isHovering {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

struct PlaylistTab: View {
    @StateObject private var preferences = AppPreferences.shared
    @StateObject private var history = DownloadHistory.shared
    
    var body: some View {
        Form {
            Section("Playlist Handling") {
                Picker("When a playlist is detected:", selection: $preferences.playlistHandling) {
                    ForEach(Array(preferences.playlistHandlingOptions.keys.sorted()), id: \.self) { key in
                        Text(preferences.playlistHandlingOptions[key] ?? key)
                            .tag(key)
                    }
                }
                
                HStack {
                    Text("Max videos to download:")
                    TextField("50", value: $preferences.playlistLimit, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text("(0 = unlimited)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Skip already downloaded videos", isOn: $preferences.skipDuplicates)
                
                Toggle("Download in reverse order (newest first)", isOn: $preferences.reversePlaylist)
            }
            
            Section("Playlist Range") {
                HStack {
                    Text("Start from video:")
                    TextField("1", value: $preferences.playlistStartIndex, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                }
                
                HStack {
                    Text("End at video:")
                    TextField("0", value: $preferences.playlistEndIndex, formatter: NumberFormatter())
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 60)
                    Text("(0 = no limit)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text("These settings apply when downloading all videos from a playlist")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section("Download History") {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(history.history.count) videos in history")
                            .font(.caption)
                        Text("History helps prevent duplicate downloads")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Clear History") {
                        history.clearHistory()
                    }
                    .disabled(history.history.isEmpty)
                    
                    Button("Clean Deleted") {
                        history.cleanupDeletedFiles()
                    }
                    .help("Remove history entries for files that no longer exist")
                }
            }
            
            Section("Tips") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Playlists are automatically detected from YouTube, Vimeo, and other supported sites", 
                          systemImage: "info.circle")
                        .font(.caption)
                    
                    Label("Individual videos can still be downloaded from playlist URLs by choosing 'First Video Only'", 
                          systemImage: "lightbulb")
                        .font(.caption)
                    
                    Label("Use the 'Ask Each Time' option to decide per-playlist how many videos to download", 
                          systemImage: "questionmark.circle")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct AdvancedTab: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var showingCookieFilePicker = false
    @State private var cookieFilePath = ""
    
    var body: some View {
        Form {
            Section("Browser Cookies") {
                Picker("Cookie Source:", selection: $preferences.cookieSource) {
                    ForEach(Array(preferences.cookieSourceOptions.keys.sorted()), id: \.self) { key in
                        Text(preferences.cookieSourceOptions[key] ?? key)
                            .tag(key)
                    }
                }
                .onChange(of: preferences.cookieSource) { oldValue, newValue in
                    if newValue == "file" {
                        showingCookieFilePicker = true
                    }
                }
                
                if preferences.cookieSource == "file" && !cookieFilePath.isEmpty {
                    HStack {
                        Text("Cookie File:")
                        Text(cookieFilePath)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("⚠️ Cookies help bypass YouTube's bot detection")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    Text("Also enables downloading private or age-restricted videos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if preferences.cookieSource != "none" && preferences.cookieSource != "file" {
                        Label("Browser must be closed for cookie extraction to work", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Divider()
            
            Section("SponsorBlock") {
                Toggle("Enable SponsorBlock", isOn: $preferences.sponsorBlockEnabled)
                    .help("Automatically skip sponsored segments in YouTube videos")
                
                if preferences.sponsorBlockEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("SponsorBlock will automatically skip:", systemImage: "forward.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("• Sponsor segments\n• Self-promotion\n• Interaction reminders\n• Non-music sections (in music videos)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                    }
                }
            }
            
            Divider()
            
            Section {
                Button("Reset All Settings to Defaults") {
                    preferences.resetToDefaults()
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .fileImporter(
            isPresented: $showingCookieFilePicker,
            allowedContentTypes: [.text, .data]
        ) { result in
            if case .success(let url) = result {
                cookieFilePath = url.path
                // Store cookie file path in UserDefaults
                UserDefaults.standard.set(cookieFilePath, forKey: "cookieFilePath")
            } else {
                // If cancelled, revert to no cookies
                preferences.cookieSource = "none"
            }
        }
    }
}

struct MaintenanceTab: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var ytdlpVersion = "Checking..."
    @State private var ytdlpLatestVersion = "Checking..."
    @State private var ffmpegVersion = "Checking..."
    @State private var ffmpegLatestVersion = "Checking..."
    @State private var isUpgradingYTDLP = false
    @State private var isUpgradingFFmpeg = false
    @State private var upgradeMessage = ""
    @State private var showingUpgradeAlert = false
    @State private var isCheckingUpdates = false
    
    private let ytdlpService = YTDLPService()
    
    var ytdlpNeedsUpdate: Bool {
        ytdlpVersion != ytdlpLatestVersion && 
        ytdlpVersion != "Not installed" && 
        ytdlpLatestVersion != "Checking..." &&
        ytdlpLatestVersion != "Unknown"
    }
    
    var ffmpegNeedsUpdate: Bool {
        ffmpegVersion != ffmpegLatestVersion && 
        ffmpegVersion != "Not installed" && 
        ffmpegLatestVersion != "Checking..." &&
        ffmpegLatestVersion != "Unknown"
    }
    
    var body: some View {
        Form {
            Section("Component Versions") {
                // yt-dlp row
                HStack {
                    Label("yt-dlp", systemImage: "arrow.down.circle")
                        .frame(width: 100)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Current:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(ytdlpVersion)
                                .font(.system(.caption, design: .monospaced))
                        }
                        HStack {
                            Text("Latest:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(ytdlpLatestVersion)
                                .font(.system(.caption, design: .monospaced))
                            if ytdlpNeedsUpdate {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .help("Update available")
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await upgradeYTDLP()
                        }
                    }) {
                        if isUpgradingYTDLP {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text(ytdlpNeedsUpdate ? "Update" : "Reinstall")
                        }
                    }
                    .disabled(isUpgradingYTDLP || ytdlpVersion == "Not installed")
                }
                
                // ffmpeg row
                HStack {
                    Label("ffmpeg", systemImage: "film")
                        .frame(width: 100)
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Current:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(ffmpegVersion)
                                .font(.system(.caption, design: .monospaced))
                        }
                        HStack {
                            Text("Latest:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(ffmpegLatestVersion)
                                .font(.system(.caption, design: .monospaced))
                            if ffmpegNeedsUpdate {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption)
                                    .help("Update available")
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        Task {
                            await upgradeFFmpeg()
                        }
                    }) {
                        if isUpgradingFFmpeg {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text(ffmpegNeedsUpdate ? "Update" : "Reinstall")
                        }
                    }
                    .disabled(isUpgradingFFmpeg || ffmpegVersion == "Not installed")
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        Task {
                            await checkVersions()
                        }
                    }) {
                        if isCheckingUpdates {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Text("Check for Updates")
                        }
                    }
                    .disabled(isCheckingUpdates)
                    
                    Button("Update All") {
                        Task {
                            await upgradeAll()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isUpgradingYTDLP || isUpgradingFFmpeg || (!ytdlpNeedsUpdate && !ffmpegNeedsUpdate))
                }
            }
            
            Section("Update Settings") {
                Toggle("Check for updates automatically", isOn: $preferences.autoCheckUpdates)
                    .help("Check for new versions daily")
                
                Toggle("Show update notifications", isOn: $preferences.showUpdateNotifications)
                    .disabled(!preferences.autoCheckUpdates)
                    .help("Display notifications when updates are available")
                
                Toggle("Install updates automatically", isOn: $preferences.autoInstallUpdates)
                    .disabled(!preferences.autoCheckUpdates)
                    .help("Automatically install updates without prompting")
                
                if preferences.autoCheckUpdates {
                    HStack {
                        Text("Last checked:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(preferences.lastUpdateCheck.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Installation") {
                if ytdlpVersion == "Not installed" || ffmpegVersion == "Not installed" {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Missing Components")
                            .font(.headline)
                        
                        Text("Install missing components using Homebrew:")
                            .font(.caption)
                        
                        HStack {
                            Text("brew install yt-dlp ffmpeg")
                                .font(.system(.body, design: .monospaced))
                                .padding(8)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                            
                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString("brew install yt-dlp ffmpeg", forType: .string)
                            }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.plain)
                            .help("Copy command")
                        }
                        
                        Link("Install Homebrew", destination: URL(string: "https://brew.sh")!)
                            .font(.caption)
                    }
                } else {
                    Label("All components installed", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            
            Section("Tips") {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Keep yt-dlp updated to enhance Fair Use enablement features that circumvent unethical corporate rent-seeking behaviors and other oppressive content restrictions", systemImage: "info.circle")
                        .font(.caption)
                    
                    Label("ffmpeg is required for merging video and audio streams", systemImage: "info.circle")
                        .font(.caption)
                    
                    Label("Updates may include important bug fixes and new site support", systemImage: "info.circle")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .onAppear {
            Task {
                await checkVersions()
            }
        }
        .alert("Upgrade Complete", isPresented: $showingUpgradeAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(upgradeMessage)
        }
    }
    
    func checkVersions() async {
        await MainActor.run {
            isCheckingUpdates = true
        }
        
        // Check yt-dlp current version
        do {
            let version = try await ytdlpService.getYTDLPVersion()
            await MainActor.run {
                ytdlpVersion = version
            }
        } catch {
            await MainActor.run {
                ytdlpVersion = "Not installed"
            }
        }
        
        // Check yt-dlp latest version
        do {
            let latest = try await ytdlpService.getLatestYTDLPVersion()
            await MainActor.run {
                ytdlpLatestVersion = latest
            }
        } catch {
            await MainActor.run {
                ytdlpLatestVersion = "Unknown"
            }
        }
        
        // Check ffmpeg current version
        do {
            let version = try await ytdlpService.getFFmpegVersion()
            await MainActor.run {
                ffmpegVersion = version
            }
        } catch {
            await MainActor.run {
                ffmpegVersion = "Not installed"
            }
        }
        
        // Check ffmpeg latest version
        do {
            let latest = try await ytdlpService.getLatestFFmpegVersion()
            await MainActor.run {
                ffmpegLatestVersion = latest
            }
        } catch {
            await MainActor.run {
                ffmpegLatestVersion = "Unknown"
            }
        }
        
        await MainActor.run {
            isCheckingUpdates = false
            preferences.lastUpdateCheck = Date()
            
            // Show notification if updates are available
            if preferences.showUpdateNotifications {
                if ytdlpNeedsUpdate || ffmpegNeedsUpdate {
                    showUpdateNotification()
                }
            }
            
            // Auto-install if enabled
            if preferences.autoInstallUpdates {
                if ytdlpNeedsUpdate || ffmpegNeedsUpdate {
                    Task {
                        await upgradeAll()
                    }
                }
            }
        }
    }
    
    func showUpdateNotification() {
        var message = "Updates available: "
        if ytdlpNeedsUpdate {
            message += "yt-dlp (\(ytdlpLatestVersion))"
        }
        if ffmpegNeedsUpdate {
            if ytdlpNeedsUpdate { message += ", " }
            message += "ffmpeg (\(ffmpegLatestVersion))"
        }
        
        upgradeMessage = message
        showingUpgradeAlert = true
    }
    
    func upgradeYTDLP() async {
        await MainActor.run {
            isUpgradingYTDLP = true
        }
        
        do {
            let newVersion = try await ytdlpService.upgradeYTDLP()
            await MainActor.run {
                ytdlpVersion = newVersion
                upgradeMessage = "yt-dlp upgraded to version \(newVersion)"
                showingUpgradeAlert = true
                isUpgradingYTDLP = false
            }
        } catch {
            await MainActor.run {
                upgradeMessage = "Upgrade failed: \(error.localizedDescription)"
                showingUpgradeAlert = true
                isUpgradingYTDLP = false
            }
        }
    }
    
    func upgradeFFmpeg() async {
        await MainActor.run {
            isUpgradingFFmpeg = true
        }
        
        do {
            let newVersion = try await ytdlpService.upgradeFFmpeg()
            await MainActor.run {
                ffmpegVersion = newVersion
                upgradeMessage = "ffmpeg upgraded to version \(newVersion)"
                showingUpgradeAlert = true
                isUpgradingFFmpeg = false
            }
        } catch {
            await MainActor.run {
                upgradeMessage = "Upgrade failed: \(error.localizedDescription)"
                showingUpgradeAlert = true
                isUpgradingFFmpeg = false
            }
        }
    }
    
    func upgradeAll() async {
        await upgradeYTDLP()
        await upgradeFFmpeg()
    }
}
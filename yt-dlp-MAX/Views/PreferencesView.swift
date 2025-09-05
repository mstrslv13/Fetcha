import SwiftUI

struct PreferencesView: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var selectedSection = "general"
    
    var body: some View {
        HSplitView {
            // Sidebar with sections
            List(selection: $selectedSection) {
                Label("General", systemImage: "gear")
                    .tag("general")
                
                Label("Naming", systemImage: "textformat")
                    .tag("naming")
                
                Label("Post-Processing", systemImage: "gearshape.2")
                    .tag("postprocessing")
                
                Label("Update", systemImage: "arrow.triangle.2.circlepath")
                    .tag("update")
                
                Label("Privacy", systemImage: "lock.shield")
                    .tag("privacy")
                
                Label("About", systemImage: "info.circle")
                    .tag("about")
            }
            .listStyle(SidebarListStyle())
            .frame(width: 150)
            
            // Content area
            ScrollView {
                switch selectedSection {
                case "general":
                    GeneralPreferencesView()
                case "naming":
                    NamingPreferencesView()
                case "postprocessing":
                    PostProcessingPreferencesView()
                case "update":
                    UpdatePreferencesView()
                case "privacy":
                    PrivacyPreferencesView()
                case "about":
                    AboutView()
                default:
                    EmptyView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 850, height: 700)
    }
}

struct GeneralPreferencesView: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var showingFolderPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            // Download Location
            VStack(alignment: .leading, spacing: 8) {
                Text("Download Location")
                    .font(.headline)
                HStack {
                    TextField("Download path", text: $preferences.downloadPath)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Choose...") {
                        showingFolderPicker = true
                    }
                    .frame(width: 80)
                }
            }
            
            // Target Quality
            VStack(alignment: .leading, spacing: 8) {
                Text("Target Quality")
                    .font(.headline)
                Picker("", selection: $preferences.defaultVideoQuality) {
                    ForEach(Array(preferences.qualityOptions.keys.sorted(by: { key1, key2 in
                        let order = ["best", "2160p", "1440p", "1080p", "720p", "480p", "360p", "worst"]
                        let index1 = order.firstIndex(of: key1) ?? 999
                        let index2 = order.firstIndex(of: key2) ?? 999
                        return index1 < index2
                    })), id: \.self) { key in
                        Text(preferences.qualityOptions[key] ?? key)
                            .tag(key)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 200)
            }
            
            // Checkboxes
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Auto-add copied URL to queue", isOn: $preferences.autoAddToQueue)
                    .help("Automatically add URLs to the download queue when copied")
                
                Toggle("Embed subtitles", isOn: $preferences.embedSubtitles)
                    .help("Embed subtitles into downloaded videos")
            }
            
            // Concurrent Downloads
            HStack {
                Text("Concurrent downloads:")
                    .frame(width: 160, alignment: .leading)
                Stepper(value: $preferences.maxConcurrentDownloads, in: 1...10) {
                    Text("\(preferences.maxConcurrentDownloads)")
                        .frame(width: 30)
                }
            }
            
            // Retry Attempts
            HStack {
                Text("Retry attempts:")
                    .frame(width: 160, alignment: .leading)
                Stepper(value: $preferences.retryAttempts, in: 0...10) {
                    Text("\(preferences.retryAttempts)")
                        .frame(width: 30)
                }
            }
            
            // Format Fallback Settings
            VStack(alignment: .leading, spacing: 8) {
                Text("Format Fallback")
                    .font(.headline)
                
                Toggle("Auto-select alternative format when unavailable", 
                       isOn: $preferences.autoSelectFallbackFormat)
                    .help("Automatically choose a similar format if the requested one isn't available")
                
                Toggle("Prefer manual format selection on errors", 
                       isOn: $preferences.preferManualFormatSelection)
                    .disabled(!preferences.autoSelectFallbackFormat)
                    .help("Show format selection dialog instead of automatic fallback")
                
                Toggle("Allow fallback to lower quality", 
                       isOn: $preferences.fallbackToLowerQuality)
                    .disabled(!preferences.autoSelectFallbackFormat)
                    .help("Use lower quality formats if higher ones aren't available")
            }
            
            // Browser Cookies
            VStack(alignment: .leading, spacing: 8) {
                Text("Browser cookies")
                    .font(.headline)
                Picker("", selection: $preferences.cookieSource) {
                    ForEach(Array(preferences.cookieSourceOptions.keys.sorted()), id: \.self) { key in
                        Text(preferences.cookieSourceOptions[key] ?? key)
                            .tag(key)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 200)
                
                Text("Cookies allow downloading private or age-restricted videos.\nBrowser must be closed for cookie extraction to work.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Reset button
            HStack {
                Spacer()
                Button("Reset all settings to defaults") {
                    preferences.resetToDefaults()
                }
                .foregroundColor(.red)
            }
            
            Spacer()
        }
        .padding(30)
        .fileImporter(
            isPresented: $showingFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case .success(let url):
                let gotAccess = url.startAccessingSecurityScopedResource()
                preferences.downloadPath = url.path
                if gotAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print("Error selecting folder: \(error)")
            }
        }
    }
}

struct NamingPreferencesView: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var templatePreview = ""
    
    let templateVariables = [
        ("%(title)s", "Video title"),
        ("%(uploader)s", "Channel/uploader name"),
        ("%(upload_date)s", "Upload date (YYYYMMDD)"),
        ("%(id)s", "Video ID"),
        ("%(playlist)s", "Playlist name"),
        ("%(playlist_index)s", "Position in playlist"),
        ("%(resolution)s", "Video resolution")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Naming")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            // Naming Template
            VStack(alignment: .leading, spacing: 8) {
                Text("Naming Template")
                    .font(.headline)
                
                TextField("%(title)s", text: Binding(
                    get: { 
                        // Remove .%(ext)s from display
                        preferences.namingTemplate.replacingOccurrences(of: ".%(ext)s", with: "")
                    },
                    set: { newValue in
                        // Always append .%(ext)s when saving
                        preferences.namingTemplate = newValue.hasSuffix(".%(ext)s") ? newValue : newValue + ".%(ext)s"
                    }
                ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: preferences.namingTemplate) { oldValue, newValue in
                        updatePreview()
                    }
                
                // Template variables - clickable
                Text("Click to add template variables:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(templateVariables, id: \.0) { variable, description in
                        Button(action: {
                            // Add variable before the extension
                            var current = preferences.namingTemplate.replacingOccurrences(of: ".%(ext)s", with: "")
                            current += variable
                            preferences.namingTemplate = current + ".%(ext)s"
                            updatePreview()
                        }) {
                            HStack {
                                Text(variable)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.accentColor)
                                Text("-")
                                    .foregroundColor(.secondary)
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(5)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Preview
                if !templatePreview.isEmpty {
                    GroupBox("Preview") {
                        Text(templatePreview)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(8)
                    }
                    .padding(.top, 10)
                }
            }
            
            // Create Subfolders
            VStack(alignment: .leading, spacing: 8) {
                Toggle("Create subfolders", isOn: $preferences.createSubfolders)
                
                if preferences.createSubfolders {
                    HStack {
                        Text("Subfolder template:")
                        TextField("%(uploader)s", text: $preferences.subfolderTemplate)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 300)
                    }
                }
            }
            
            // Filename Sanitization
            VStack(alignment: .leading, spacing: 8) {
                Text("Filename Sanitization")
                    .font(.headline)
                    .padding(.top, 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Remove special characters", isOn: $preferences.removeSpecialCharacters)
                        .help("Remove characters that may cause issues in filenames")
                    
                    Toggle("Replace spaces with underscores", isOn: $preferences.replaceSpacesWithUnderscores)
                        .help("Replace all spaces in filenames with underscores")
                    
                    Toggle("Limit filename length", isOn: $preferences.limitFilenameLength)
                        .help("Restrict filename length to filesystem limits")
                }
                .padding(.leading, 10)
            }
            
            Spacer()
        }
        .padding(30)
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

struct PostProcessingPreferencesView: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var showingFfmpegPicker = false
    @State private var ffmpegStatus = "Checking..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Post-Processing")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Enable Post-Processing
            VStack(alignment: .leading, spacing: 12) {
                Toggle("Enable post-processing", isOn: $preferences.enablePostProcessing)
                    .help("Automatically convert downloaded files to preferred container format")
                
                if preferences.enablePostProcessing {
                    // Container Format Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preferred Container Format")
                            .font(.headline)
                        
                        Picker("Container:", selection: $preferences.preferredContainer) {
                            ForEach(preferences.containerFormatOptions.keys.sorted(), id: \.self) { key in
                                Text(preferences.containerFormatOptions[key] ?? key)
                                    .tag(key)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 250)
                        
                        Text("Files will be converted to this format after download")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.leading, 20)
                    
                    // Keep Original Files
                    Toggle("Keep original files after processing", isOn: $preferences.keepOriginalAfterProcessing)
                        .padding(.leading, 20)
                        .help("Preserve the original downloaded file alongside the converted version")
                    
                    Divider()
                    
                    // Audio Extraction Section
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Enable Audio Extraction", isOn: $preferences.enableAudioExtraction)
                            .font(.headline)
                            .help("Extract audio from downloaded videos into separate audio files")
                        
                        if preferences.enableAudioExtraction {
                            VStack(alignment: .leading, spacing: 12) {
                                // Audio Format Selection
                                HStack {
                                    Text("Audio Format:")
                                        .frame(width: 120, alignment: .leading)
                                    Picker("", selection: $preferences.audioExtractionFormat) {
                                        Text("MP3").tag("mp3")
                                        Text("M4A (AAC)").tag("m4a")
                                        Text("WAV").tag("wav")
                                        Text("FLAC").tag("flac")
                                        Text("OGG Vorbis").tag("ogg")
                                        Text("OPUS").tag("opus")
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .frame(width: 150)
                                }
                                
                                // Audio Quality/Bitrate
                                HStack {
                                    Text("Audio Quality:")
                                        .frame(width: 120, alignment: .leading)
                                    
                                    if preferences.audioExtractionFormat == "wav" || preferences.audioExtractionFormat == "flac" {
                                        Text("Lossless")
                                            .foregroundColor(.secondary)
                                    } else {
                                        Picker("", selection: $preferences.audioExtractionBitrate) {
                                            Text("128k").tag("128k")
                                            Text("192k").tag("192k")
                                            Text("256k").tag("256k")
                                            Text("320k (High)").tag("320k")
                                        }
                                        .pickerStyle(MenuPickerStyle())
                                        .frame(width: 150)
                                    }
                                }
                                
                                // Keep Video File
                                Toggle("Keep video file after extraction", isOn: $preferences.keepVideoAfterExtraction)
                                    .help("Preserve the original video file alongside the extracted audio")
                            }
                            .padding(.leading, 20)
                        }
                    }
                    
                    Divider()
                    
                    // ffmpeg Configuration
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ffmpeg Configuration")
                            .font(.headline)
                        
                        HStack {
                            Text("ffmpeg path:")
                            TextField("Auto-detect", text: $preferences.ffmpegPath)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 300)
                                .help("Leave empty to auto-detect ffmpeg")
                            
                            Button("Browse...") {
                                showingFfmpegPicker = true
                            }
                        }
                        
                        HStack {
                            Text("Status:")
                            Text(ffmpegStatus)
                                .foregroundColor(ffmpegStatus.contains("Found") ? .green : .orange)
                                .font(.caption)
                        }
                    }
                    .padding(.leading, 20)
                }
            }
            
            // Information
            VStack(alignment: .leading, spacing: 8) {
                Text("About Post-Processing")
                    .font(.headline)
                    .padding(.top, 10)
                
                Text("Post-processing uses ffmpeg to convert downloaded videos to your preferred container format. This is useful for:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Ensuring compatibility with specific devices or software")
                    Text("• Reducing file size with more efficient containers")
                    Text("• Preserving quality while changing formats")
                    Text("• Standardizing your media library format")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 10)
            }
            
            Spacer()
        }
        .padding(30)
        .onAppear {
            checkFfmpegStatus()
        }
        .fileImporter(
            isPresented: $showingFfmpegPicker,
            allowedContentTypes: [.unixExecutable],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let files) = result, let file = files.first {
                preferences.ffmpegPath = file.path
                checkFfmpegStatus()
            }
        }
    }
    
    func checkFfmpegStatus() {
        let ffmpegPath = preferences.resolvedFfmpegPath
        
        Task {
            do {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: ffmpegPath)
                task.arguments = ["-version"]
                
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = Pipe()
                
                try task.run()
                task.waitUntilExit()
                
                if task.terminationStatus == 0 {
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let output = String(data: data, encoding: .utf8),
                       let firstLine = output.split(separator: "\n").first {
                        await MainActor.run {
                            ffmpegStatus = "Found: \(firstLine)"
                        }
                    } else {
                        await MainActor.run {
                            ffmpegStatus = "Found at: \(ffmpegPath)"
                        }
                    }
                } else {
                    await MainActor.run {
                        ffmpegStatus = "Invalid ffmpeg executable"
                    }
                }
            } catch {
                await MainActor.run {
                    ffmpegStatus = "Not found. Please install ffmpeg."
                }
            }
        }
    }
}

struct UpdatePreferencesView: View {
    @StateObject private var preferences = AppPreferences.shared
    @State private var ytdlpVersion = "Checking..."
    @State private var ffmpegVersion = "Checking..."
    @State private var isCheckingUpdates = false
    @State private var isUpdatingYtdlp = false
    @State private var isUpdatingFfmpeg = false
    @State private var updateMessage = ""
    @State private var hasCheckedForUpdates = false
    @State private var ytdlpNeedsUpdate = false
    @State private var ffmpegNeedsUpdate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Update")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            // Version Information
            GroupBox("Installed Versions") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "arrow.down.circle")
                            .foregroundColor(.secondary)
                        Text("yt-dlp:")
                            .frame(width: 80, alignment: .leading)
                        Text(ytdlpVersion)
                            .foregroundColor(ytdlpNeedsUpdate ? .orange : .secondary)
                        Spacer()
                        Button("Update") {
                            updateYtdlp()
                        }
                        .disabled(!hasCheckedForUpdates || !ytdlpNeedsUpdate || isUpdatingYtdlp)
                        .help(!hasCheckedForUpdates ? "Check for updates first" : 
                              !ytdlpNeedsUpdate ? "Already up to date" : "Update yt-dlp")
                    }
                    
                    HStack {
                        Image(systemName: "film")
                            .foregroundColor(.secondary)
                        Text("ffmpeg:")
                            .frame(width: 80, alignment: .leading)
                        Text(ffmpegVersion)
                            .foregroundColor(ffmpegNeedsUpdate ? .orange : .secondary)
                        Spacer()
                        Button("Update") {
                            updateFfmpeg()
                        }
                        .disabled(!hasCheckedForUpdates || !ffmpegNeedsUpdate || isUpdatingFfmpeg)
                        .help(!hasCheckedForUpdates ? "Check for updates first" : 
                              !ffmpegNeedsUpdate ? "Already up to date" : "Update ffmpeg")
                    }
                }
                .padding(12)
            }
            
            // Update Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("Update Settings")
                    .font(.headline)
                
                Toggle("Automatically check for updates", isOn: $preferences.autoUpdateCheck)
                Toggle("Automatically install updates", isOn: $preferences.autoInstallUpdates)
                    .disabled(!preferences.autoUpdateCheck)
                Toggle("Show notifications", isOn: $preferences.notifyUpdates)
                    .disabled(!preferences.autoUpdateCheck)
            }
            
            // Check Now Button
            HStack {
                Button("Check for Updates Now") {
                    checkForUpdates()
                }
                .disabled(isCheckingUpdates)
                
                if isCheckingUpdates {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            // Status Message
            if !updateMessage.isEmpty {
                Text(updateMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            
            Spacer()
        }
        .padding(30)
        .onAppear {
            checkVersions()
        }
    }
    
    func checkVersions() {
        Task {
            // Check yt-dlp version
            do {
                let result = try await runCommand("/opt/homebrew/bin/yt-dlp --version")
                await MainActor.run {
                    ytdlpVersion = result.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } catch {
                await MainActor.run {
                    ytdlpVersion = "Not installed"
                }
            }
            
            // Check ffmpeg version
            do {
                let result = try await runCommand("/opt/homebrew/bin/ffmpeg -version")
                if let firstLine = result.split(separator: "\n").first {
                    let version = String(firstLine).replacingOccurrences(of: "ffmpeg version ", with: "")
                    await MainActor.run {
                        ffmpegVersion = String(version.split(separator: " ").first ?? "Unknown")
                    }
                }
            } catch {
                await MainActor.run {
                    ffmpegVersion = "Not installed"
                }
            }
        }
    }
    
    func checkForUpdates() {
        isCheckingUpdates = true
        updateMessage = "Checking for updates..."
        hasCheckedForUpdates = false
        
        Task {
            do {
                _ = try await runCommand("brew update")
                let outdated = try await runCommand("brew outdated")
                
                await MainActor.run {
                    ytdlpNeedsUpdate = outdated.contains("yt-dlp")
                    ffmpegNeedsUpdate = outdated.contains("ffmpeg")
                    hasCheckedForUpdates = true
                    
                    if ytdlpNeedsUpdate || ffmpegNeedsUpdate {
                        var needsUpdate: [String] = []
                        if ytdlpNeedsUpdate { needsUpdate.append("yt-dlp") }
                        if ffmpegNeedsUpdate { needsUpdate.append("ffmpeg") }
                        updateMessage = "Updates available for: \(needsUpdate.joined(separator: ", "))"
                    } else {
                        updateMessage = "Everything is up to date"
                    }
                    isCheckingUpdates = false
                }
            } catch {
                await MainActor.run {
                    updateMessage = "Failed to check for updates"
                    isCheckingUpdates = false
                    hasCheckedForUpdates = false
                }
            }
        }
    }
    
    func updateYtdlp() {
        isUpdatingYtdlp = true
        updateMessage = "Updating yt-dlp..."
        
        Task {
            do {
                _ = try await runCommand("brew upgrade yt-dlp")
                await MainActor.run {
                    updateMessage = "yt-dlp updated successfully"
                    isUpdatingYtdlp = false
                    ytdlpNeedsUpdate = false
                    checkVersions()
                }
            } catch {
                await MainActor.run {
                    updateMessage = "Failed to update yt-dlp"
                    isUpdatingYtdlp = false
                }
            }
        }
    }
    
    func updateFfmpeg() {
        isUpdatingFfmpeg = true
        updateMessage = "Updating ffmpeg..."
        
        Task {
            do {
                _ = try await runCommand("brew upgrade ffmpeg")
                await MainActor.run {
                    updateMessage = "ffmpeg updated successfully"
                    isUpdatingFfmpeg = false
                    ffmpegNeedsUpdate = false
                    checkVersions()
                }
            } catch {
                await MainActor.run {
                    updateMessage = "Failed to update ffmpeg"
                    isUpdatingFfmpeg = false
                }
            }
        }
    }
    
    func runCommand(_ command: String) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = ["-c", command]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

struct PrivacyPreferencesView: View {
    @StateObject private var preferences = AppPreferences.shared
    @StateObject private var downloadHistory = DownloadHistory.shared
    @State private var showingClearHistoryConfirmation = false
    @State private var showingPrivateFolderPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Privacy & History")
                .font(.title)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            // Private Mode Section
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Private Instance Mode")
                        .font(.headline)
                    
                    Toggle("Enable Private Mode", isOn: $preferences.privateMode)
                        .onChange(of: preferences.privateMode) { _, newValue in
                            if newValue {
                                // Reload history for private mode
                                downloadHistory.loadHistory()
                            }
                        }
                    
                    Text("In private mode, download history is not saved and a separate download location can be used.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if preferences.privateMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Private Download Location")
                                .font(.subheadline)
                            
                            HStack {
                                TextField("Private download path (optional)", text: $preferences.privateDownloadPath)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button("Choose...") {
                                    showingPrivateFolderPicker = true
                                }
                                .frame(width: 80)
                            }
                            
                            Toggle("Show private mode indicator", isOn: $preferences.privateModeShowIndicator)
                                .help("Shows a visual indicator when private mode is active")
                        }
                        .padding(.leading, 20)
                    }
                }
            }
            
            // History Management Section
            GroupBox {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Download History")
                        .font(.headline)
                    
                    HStack {
                        Text("Current history items:")
                        Text("\(downloadHistory.history.count)")
                            .fontWeight(.semibold)
                    }
                    
                    // Auto-clear settings
                    HStack {
                        Text("Auto-clear history:")
                        Picker("", selection: $preferences.historyAutoClear) {
                            ForEach(Array(preferences.historyAutoClearOptions.keys.sorted { key1, key2 in
                                let order = ["never", "1", "7", "30", "90"]
                                let index1 = order.firstIndex(of: key1) ?? 999
                                let index2 = order.firstIndex(of: key2) ?? 999
                                return index1 < index2
                            })), id: \.self) { key in
                                Text(preferences.historyAutoClearOptions[key] ?? key)
                                    .tag(key)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 150)
                        .onChange(of: preferences.historyAutoClear) { _, newValue in
                            // Apply auto-clear immediately when changed
                            downloadHistory.performAutoClear()
                        }
                    }
                    
                    Text("Automatically remove history items older than the specified time.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    // Manual clear actions
                    VStack(alignment: .leading, spacing: 12) {
                        Button("Clear All History") {
                            showingClearHistoryConfirmation = true
                        }
                        .foregroundColor(.red)
                        
                        Button("Clean Up Deleted Files") {
                            downloadHistory.cleanupDeletedFiles()
                        }
                        .help("Remove history entries for files that no longer exist")
                        
                        if preferences.historyAutoClear != "never" {
                            Button("Apply Auto-Clear Now") {
                                downloadHistory.performAutoClear()
                            }
                            .help("Immediately apply the auto-clear setting")
                        }
                    }
                }
            }
            
            // Embed Options
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Media Metadata")
                        .font(.headline)
                    
                    Toggle("Embed thumbnails in video files", isOn: $preferences.embedThumbnail)
                        .help("Embeds thumbnail images into downloaded video files")
                    
                    Text("Thumbnails are always saved separately for display in the app.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(30)
        .alert("Clear All History?", isPresented: $showingClearHistoryConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                downloadHistory.clearHistory(skipConfirmation: true)
            }
        } message: {
            Text("This will permanently remove all download history. This action cannot be undone.")
        }
        .fileImporter(
            isPresented: $showingPrivateFolderPicker,
            allowedContentTypes: [.folder]
        ) { result in
            switch result {
            case .success(let url):
                let gotAccess = url.startAccessingSecurityScopedResource()
                preferences.privateDownloadPath = url.path
                if gotAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            case .failure(let error):
                print("Error selecting private folder: \(error)")
            }
        }
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 20)
            
            // App Icon - Dog logo
            Image("DogLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            
            Text("Fetcha")
                .font(.system(size: 38))
                .fontWeight(.bold)
            
            Text("Version 0.9.0")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Text("A simple, powerful streaming media fetcher for macOS")
                .font(.system(size: 16))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Divider()
                .frame(width: 200)
                .padding(.vertical, 4)
            
            VStack(spacing: 4) {
                Text("In loving memory of")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("Zephy")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("2012 - 2022")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
            
            Divider()
                .frame(width: 200)
                .padding(.vertical, 4)
            
            VStack(spacing: 6) {
                Text("Copyright © 2025 William Azada")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                Text("Contact: dev@fetcha.stream")
                    .font(.system(size: 14))
                    .foregroundColor(.accentColor)
            }
            
            Spacer(minLength: 15)
            
            // Coffee button
            Link(destination: URL(string: "https://buymeacoffee.com/mstrslva")!) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Buy me a coffee")
                }
                .font(.system(size: 14))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack(spacing: 20) {
                Link("View on GitHub", destination: URL(string: "https://github.com/mstrslv13/fetcha")!)
                    .font(.system(size: 14))
                
                Link("Report Issue", destination: URL(string: "https://github.com/mstrslv13/fetcha/issues")!)
                    .font(.system(size: 14))
            }
            
            Spacer(minLength: 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(30)
    }
}
import Foundation
import SwiftUI

class AppPreferences: ObservableObject {
    static let shared = AppPreferences()
    
    @AppStorage("downloadPath") var downloadPath: String = ""
    @AppStorage("audioDownloadPath") var audioDownloadPath: String = ""
    @AppStorage("videoOnlyDownloadPath") var videoOnlyDownloadPath: String = ""
    @AppStorage("useSeparateLocations") var useSeparateLocations: Bool = false
    @AppStorage("defaultVideoQuality") var defaultVideoQuality: String = "best"
    @AppStorage("downloadAudio") var downloadAudio: Bool = false
    @AppStorage("audioFormat") var audioFormat: String = "mp3"
    @AppStorage("keepOriginalFiles") var keepOriginalFiles: Bool = false
    @AppStorage("autoAddToQueue") var autoAddToQueue: Bool = true
    @AppStorage("skipMetadataFetch") var skipMetadataFetch: Bool = false
    @AppStorage("singlePaneMode") var singlePaneMode: Bool = true
    @AppStorage("maxConcurrentDownloads") var maxConcurrentDownloads: Int = 3
    @AppStorage("namingTemplate") var namingTemplate: String = "%(title)s.%(ext)s"
    @AppStorage("createSubfolders") var createSubfolders: Bool = false
    @AppStorage("subfolderTemplate") var subfolderTemplate: String = ""
    
    // Filename sanitization options (yt-dlp)
    @AppStorage("removeSpecialCharacters") var removeSpecialCharacters: Bool = false
    @AppStorage("replaceSpacesWithUnderscores") var replaceSpacesWithUnderscores: Bool = false
    @AppStorage("limitFilenameLength") var limitFilenameLength: Bool = false
    
    @AppStorage("embedThumbnail") var embedThumbnail: Bool = false
    @AppStorage("embedSubtitles") var embedSubtitles: Bool = false
    @AppStorage("subtitleLanguages") var subtitleLanguages: String = "en"
    @AppStorage("showDebugConsole") var showDebugConsole: Bool = false
    @AppStorage("rateLimitKbps") var rateLimitKbps: Int = 0
    @AppStorage("retryAttempts") var retryAttempts: Int = 3
    @AppStorage("cookieSource") var cookieSource: String = "safari"
    
    // Update preferences
    @AppStorage("autoUpdateCheck") var autoUpdateCheck: Bool = true
    @AppStorage("autoInstallUpdates") var autoInstallUpdates: Bool = true
    @AppStorage("notifyUpdates") var notifyUpdates: Bool = true
    
    // Playlist handling preferences
    @AppStorage("playlistHandling") var playlistHandling: String = "ask"  // ask, all, single
    @AppStorage("playlistLimit") var playlistLimit: Int = 50  // Max items to download from playlist
    @AppStorage("skipDuplicates") var skipDuplicates: Bool = true  // Skip already downloaded videos
    @AppStorage("playlistStartIndex") var playlistStartIndex: Int = 1  // Start downloading from this index
    @AppStorage("playlistEndIndex") var playlistEndIndex: Int = 0  // End at this index (0 = no limit)
    @AppStorage("reversePlaylist") var reversePlaylist: Bool = false  // Download playlist in reverse order
    
    // Format Fallback Settings
    @AppStorage("autoSelectFallbackFormat") var autoSelectFallbackFormat: Bool = true
    @AppStorage("preferManualFormatSelection") var preferManualFormatSelection: Bool = false
    @AppStorage("fallbackToLowerQuality") var fallbackToLowerQuality: Bool = true
    @AppStorage("maxFallbackQuality") var maxFallbackQuality: Int = 1080
    
    // Post-Processing Settings
    @AppStorage("enablePostProcessing") var enablePostProcessing: Bool = false
    @AppStorage("preferredContainer") var preferredContainer: String = "mp4"
    @AppStorage("keepOriginalAfterProcessing") var keepOriginalAfterProcessing: Bool = false
    @AppStorage("ffmpegPath") var ffmpegPath: String = ""
    
    // Audio Extraction Settings
    @AppStorage("enableAudioExtraction") var enableAudioExtraction: Bool = false
    @AppStorage("audioExtractionFormat") var audioExtractionFormat: String = "mp3"
    @AppStorage("audioExtractionBitrate") var audioExtractionBitrate: String = "320k"
    @AppStorage("audioExtractionQuality") var audioExtractionQuality: String = "high"
    @AppStorage("keepVideoAfterExtraction") var keepVideoAfterExtraction: Bool = true
    
    // History Management Settings
    @AppStorage("historyAutoClear") var historyAutoClear: String = "never"  // never, 1, 7, 30, 90 days
    @AppStorage("privateMode") var privateMode: Bool = false
    @AppStorage("privateDownloadPath") var privateDownloadPath: String = ""
    @AppStorage("privateModeShowIndicator") var privateModeShowIndicator: Bool = true
    
    // Computed property for actual download path
    var resolvedDownloadPath: String {
        // Use private path if in private mode
        if privateMode && !privateDownloadPath.isEmpty {
            return NSString(string: privateDownloadPath).expandingTildeInPath
        }
        
        if downloadPath.isEmpty {
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "~/Downloads"
        }
        return NSString(string: downloadPath).expandingTildeInPath
    }
    
    var resolvedAudioPath: String {
        if audioDownloadPath.isEmpty {
            return resolvedDownloadPath
        }
        return NSString(string: audioDownloadPath).expandingTildeInPath
    }
    
    var resolvedVideoOnlyPath: String {
        if videoOnlyDownloadPath.isEmpty {
            return resolvedDownloadPath
        }
        return NSString(string: videoOnlyDownloadPath).expandingTildeInPath
    }
    
    var resolvedFfmpegPath: String {
        if !ffmpegPath.isEmpty {
            return NSString(string: ffmpegPath).expandingTildeInPath
        }
        // Auto-detect ffmpeg
        let paths = [
            "/opt/homebrew/bin/ffmpeg",  // Apple Silicon Homebrew
            "/usr/local/bin/ffmpeg",      // Intel Homebrew
            "/usr/bin/ffmpeg"              // System
        ]
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        // Try which command
        let task = Process()
        task.launchPath = "/usr/bin/which"
        task.arguments = ["ffmpeg"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do {
            try task.run()
            task.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {
            // Ignore errors
        }
        return "ffmpeg"  // Fallback to PATH
    }
    
    // Available quality options
    let qualityOptions = [
        "best": "Best Quality",
        "2160p": "4K (2160p)",
        "1440p": "2K (1440p)", 
        "1080p": "Full HD (1080p)",
        "720p": "HD (720p)",
        "480p": "SD (480p)",
        "360p": "Mobile (360p)",
        "worst": "Lowest Quality"
    ]
    
    // Audio format options
    let audioFormatOptions = [
        "mp3": "MP3",
        "m4a": "M4A",
        "wav": "WAV",
        "flac": "FLAC",
        "opus": "Opus",
        "vorbis": "Vorbis"
    ]
    
    // Cookie source options
    let cookieSourceOptions = [
        "none": "No Cookies",
        "safari": "Safari",
        "chrome": "Chrome",
        "brave": "Brave",
        "firefox": "Firefox",
        "edge": "Edge",
        "file": "From File..."
    ]
    
    // Playlist handling options
    let playlistHandlingOptions = [
        "ask": "Ask Each Time",
        "all": "Download All Videos",
        "single": "First Video Only"
    ]
    
    // Naming template presets
    let namingTemplatePresets = [
        "%(title)s.%(ext)s": "Video Title",
        "%(title)s - %(uploader)s.%(ext)s": "Title - Uploader",
        "%(upload_date)s - %(title)s.%(ext)s": "Date - Title",
        "%(uploader)s/%(title)s.%(ext)s": "Uploader Folder/Title",
        "%(playlist)s/%(playlist_index)s - %(title)s.%(ext)s": "Playlist/Index - Title"
    ]
    
    // History auto-clear options
    let historyAutoClearOptions = [
        "never": "Never",
        "1": "After 1 day",
        "7": "After 7 days",
        "30": "After 30 days",
        "90": "After 90 days"
    ]
    
    // Container format options
    let containerFormatOptions = [
        "mp4": "MP4 (Most Compatible)",
        "mkv": "MKV (Preserve Quality)",
        "mov": "MOV (Apple)",
        "avi": "AVI (Legacy)",
        "webm": "WebM (Web)",
        "flv": "FLV (Flash)"
    ]
    
    private init() {
        // Set default download path if not set
        if downloadPath.isEmpty {
            let defaultPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.appendingPathComponent("Fetcha").path ?? "~/Downloads/Fetcha"
            downloadPath = defaultPath
            // Create directory if it doesn't exist
            try? FileManager.default.createDirectory(atPath: NSString(string: defaultPath).expandingTildeInPath, withIntermediateDirectories: true)
        }
    }
    
    func resetToDefaults() {
        let defaultPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.appendingPathComponent("Fetcha").path ?? "~/Downloads/Fetcha"
        
        // File paths
        downloadPath = defaultPath
        audioDownloadPath = ""
        videoOnlyDownloadPath = ""
        useSeparateLocations = false
        
        // Download settings
        defaultVideoQuality = "best"
        downloadAudio = false
        audioFormat = "mp3"
        keepOriginalFiles = false
        autoAddToQueue = true
        skipMetadataFetch = false
        singlePaneMode = true
        maxConcurrentDownloads = 3
        
        // Naming settings
        namingTemplate = "%(title)s.%(ext)s"
        createSubfolders = false
        subfolderTemplate = ""
        removeSpecialCharacters = false
        replaceSpacesWithUnderscores = false
        limitFilenameLength = false
        
        // Metadata settings
        embedThumbnail = false
        embedSubtitles = false
        subtitleLanguages = "en"
        
        // Performance settings
        showDebugConsole = false
        rateLimitKbps = 0
        retryAttempts = 3
        cookieSource = "safari"
        
        // Update preferences
        autoUpdateCheck = true
        autoInstallUpdates = true
        notifyUpdates = true
        
        // Playlist settings
        playlistHandling = "ask"
        playlistLimit = 50
        skipDuplicates = true
        playlistStartIndex = 1
        playlistEndIndex = 0
        reversePlaylist = false
        
        // Format fallback settings
        autoSelectFallbackFormat = true
        preferManualFormatSelection = false
        fallbackToLowerQuality = true
        maxFallbackQuality = 1080
        
        // Post-processing settings
        enablePostProcessing = false
        preferredContainer = "mp4"
        keepOriginalAfterProcessing = false
        ffmpegPath = ""
        
        // Audio extraction settings
        enableAudioExtraction = false
        audioExtractionFormat = "mp3"
        audioExtractionBitrate = "320k"
        audioExtractionQuality = "high"
        keepVideoAfterExtraction = true
        
        // History settings
        historyAutoClear = "never"
        privateMode = false
        privateDownloadPath = ""
        privateModeShowIndicator = true
    }
}
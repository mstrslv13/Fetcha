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
    @AppStorage("autoAddToQueue") var autoAddToQueue: Bool = false
    @AppStorage("skipMetadataFetch") var skipMetadataFetch: Bool = false
    @AppStorage("singlePaneMode") var singlePaneMode: Bool = true
    @AppStorage("maxConcurrentDownloads") var maxConcurrentDownloads: Int = 3
    @AppStorage("namingTemplate") var namingTemplate: String = "%(title)s.%(ext)s"
    @AppStorage("createSubfolders") var createSubfolders: Bool = false
    @AppStorage("subfolderTemplate") var subfolderTemplate: String = ""
    @AppStorage("embedThumbnail") var embedThumbnail: Bool = false
    @AppStorage("embedSubtitles") var embedSubtitles: Bool = false
    @AppStorage("subtitleLanguages") var subtitleLanguages: String = "en"
    @AppStorage("showDebugConsole") var showDebugConsole: Bool = false
    @AppStorage("rateLimitKbps") var rateLimitKbps: Int = 0
    @AppStorage("retryAttempts") var retryAttempts: Int = 3
    @AppStorage("cookieSource") var cookieSource: String = "none"
    @AppStorage("sponsorBlockEnabled") var sponsorBlockEnabled: Bool = false
    
    // Update preferences
    @AppStorage("autoCheckUpdates") var autoCheckUpdates: Bool = true
    @AppStorage("showUpdateNotifications") var showUpdateNotifications: Bool = true
    @AppStorage("autoInstallUpdates") var autoInstallUpdates: Bool = false
    @AppStorage("lastUpdateCheck") var lastUpdateCheck: Date = Date.distantPast
    
    // Playlist handling preferences
    @AppStorage("playlistHandling") var playlistHandling: String = "ask"  // ask, all, single
    @AppStorage("playlistLimit") var playlistLimit: Int = 50  // Max items to download from playlist
    @AppStorage("skipDuplicates") var skipDuplicates: Bool = true  // Skip already downloaded videos
    @AppStorage("playlistStartIndex") var playlistStartIndex: Int = 1  // Start downloading from this index
    @AppStorage("playlistEndIndex") var playlistEndIndex: Int = 0  // End at this index (0 = no limit)
    @AppStorage("reversePlaylist") var reversePlaylist: Bool = false  // Download playlist in reverse order
    
    // Computed property for actual download path
    var resolvedDownloadPath: String {
        if downloadPath.isEmpty {
            let defaultPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path 
                ?? NSHomeDirectory() + "/Downloads"
            return defaultPath
        }
        // Always expand tilde paths
        if downloadPath.hasPrefix("~") {
            return NSString(string: downloadPath).expandingTildeInPath
        }
        return downloadPath
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
    
    private init() {
        // Set default download path if not set
        if downloadPath.isEmpty {
            downloadPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "~/Downloads"
        }
    }
    
    func resetToDefaults() {
        downloadPath = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path ?? "~/Downloads"
        defaultVideoQuality = "best"
        downloadAudio = false
        audioFormat = "mp3"
        keepOriginalFiles = false
        autoAddToQueue = false
        skipMetadataFetch = false
        singlePaneMode = true
        maxConcurrentDownloads = 3
        namingTemplate = "%(title)s.%(ext)s"
        createSubfolders = false
        subfolderTemplate = ""
        embedThumbnail = false
        embedSubtitles = false
        subtitleLanguages = "en"
        showDebugConsole = false
        rateLimitKbps = 0
        retryAttempts = 3
        cookieSource = "none"
        sponsorBlockEnabled = false
        playlistHandling = "ask"
        playlistLimit = 50
        skipDuplicates = true
        reversePlaylist = false
    }
}
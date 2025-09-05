import Foundation

struct ErrorMessageFormatter {
    
    struct ErrorInfo {
        let message: String
        let hint: String?
        let recoveryOptions: [String]
    }
    
    // Convert technical errors to user-friendly messages with hints
    static func formatError(_ error: Error) -> ErrorInfo {
        let errorString = error.localizedDescription.lowercased()
        
        // Network-related errors
        if errorString.contains("connection") || errorString.contains("network") || errorString.contains("timed out") {
            return ErrorInfo(
                message: "Unable to connect to the server",
                hint: "This might be a temporary network issue",
                recoveryOptions: [
                    "Check your internet connection",
                    "Try again in a few moments",
                    "Check if the website is accessible in your browser"
                ]
            )
        }
        
        // File/permission errors
        if errorString.contains("permission") || errorString.contains("denied") {
            return ErrorInfo(
                message: "Permission denied",
                hint: "The app doesn't have permission to access this location",
                recoveryOptions: [
                    "Check folder permissions in Finder",
                    "Choose a different download location in Preferences",
                    "Ensure the app has Full Disk Access in System Settings"
                ]
            )
        }
        
        if errorString.contains("no such file") || errorString.contains("not found") {
            return ErrorInfo(
                message: "File or folder not found",
                hint: "The requested location doesn't exist",
                recoveryOptions: [
                    "Verify the download folder exists",
                    "Check if the file was moved or deleted",
                    "Reset download location in Preferences"
                ]
            )
        }
        
        if errorString.contains("disk") || errorString.contains("space") {
            return ErrorInfo(
                message: "Not enough disk space",
                hint: "Your disk is running low on space",
                recoveryOptions: [
                    "Free up disk space",
                    "Choose a different download location",
                    "Delete completed downloads you no longer need"
                ]
            )
        }
        
        // Download-specific errors
        if errorString.contains("json") || errorString.contains("parse") {
            return ErrorInfo(
                message: "Unable to process video information",
                hint: "The video format might have changed",
                recoveryOptions: [
                    "Try refreshing the video metadata",
                    "Check if the video is still available",
                    "Update yt-dlp using: brew upgrade yt-dlp"
                ]
            )
        }
        
        if errorString.contains("playlist") {
            return ErrorInfo(
                message: "Unable to load playlist",
                hint: "The playlist might be private or deleted",
                recoveryOptions: [
                    "Verify the playlist is public",
                    "Try importing individual videos instead",
                    "Check if you need to be logged in"
                ]
            )
        }
        
        if errorString.contains("format") {
            return ErrorInfo(
                message: "Video format not available",
                hint: "The requested quality might not exist for this video",
                recoveryOptions: [
                    "Try a different quality setting",
                    "Use 'Best Available' format option",
                    "Check if the video has the requested resolution"
                ]
            )
        }
        
        if errorString.contains("ffmpeg") {
            return ErrorInfo(
                message: "Video processing failed",
                hint: "FFmpeg is required for merging video and audio",
                recoveryOptions: [
                    "Install ffmpeg: brew install ffmpeg",
                    "Verify ffmpeg is in your PATH",
                    "Try downloading audio-only or video-only"
                ]
            )
        }
        
        if errorString.contains("yt-dlp") || errorString.contains("youtube-dl") {
            return ErrorInfo(
                message: "Download tool not found",
                hint: "yt-dlp is required for downloading",
                recoveryOptions: [
                    "Install yt-dlp: brew install yt-dlp",
                    "Check if yt-dlp is in /usr/local/bin or /opt/homebrew/bin",
                    "Restart the app after installation"
                ]
            )
        }
        
        // Cookie/authentication errors
        if errorString.contains("cookie") || errorString.contains("auth") || errorString.contains("login") {
            return ErrorInfo(
                message: "Authentication required",
                hint: "This video requires login credentials",
                recoveryOptions: [
                    "Export cookies from your browser",
                    "Check if the video is behind a paywall",
                    "Verify your account has access to this content"
                ]
            )
        }
        
        // Age restriction/private video
        if errorString.contains("age") || errorString.contains("restrict") || errorString.contains("private") {
            return ErrorInfo(
                message: "Video is restricted or private",
                hint: "This video has viewing restrictions",
                recoveryOptions: [
                    "Sign in with an account that has access",
                    "Export browser cookies if you're logged in",
                    "Check if the video is age-restricted"
                ]
            )
        }
        
        // Update errors
        if errorString.contains("update") {
            return ErrorInfo(
                message: "Update check failed",
                hint: "Unable to check for updates",
                recoveryOptions: [
                    "Check your internet connection",
                    "Update manually: brew upgrade yt-dlp",
                    "Try again later"
                ]
            )
        }
        
        // Default for unknown errors
        return ErrorInfo(
            message: "An unexpected error occurred",
            hint: "This might be a temporary issue",
            recoveryOptions: [
                "Try again",
                "Check the Debug Console for details",
                "Report this issue if it persists"
            ]
        )
    }
    
    // Convert technical errors to user-friendly messages
    static func userFriendlyMessage(for error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        // Network-related errors
        if errorString.contains("connection") || errorString.contains("network") || errorString.contains("timed out") {
            return "Unable to connect. Please check your internet connection and try again."
        }
        
        // File/permission errors
        if errorString.contains("permission") || errorString.contains("denied") {
            return "Permission denied. Please check that the app has access to the selected folder."
        }
        
        if errorString.contains("no such file") || errorString.contains("not found") {
            return "The requested file or folder could not be found."
        }
        
        if errorString.contains("disk") || errorString.contains("space") {
            return "Not enough disk space. Please free up some space and try again."
        }
        
        // Download-specific errors
        if errorString.contains("json") || errorString.contains("parse") {
            return "Unable to process video information. The video may be unavailable or restricted."
        }
        
        if errorString.contains("playlist") {
            return "Unable to load playlist. It may be private or unavailable."
        }
        
        if errorString.contains("format") {
            return "The requested video format is not available. Please try a different quality setting."
        }
        
        if errorString.contains("ffmpeg") {
            return "Video processing failed. Please ensure ffmpeg is installed correctly."
        }
        
        if errorString.contains("yt-dlp") || errorString.contains("youtube-dl") {
            return "Download tool not found. Please check that yt-dlp is installed."
        }
        
        // Cookie/authentication errors
        if errorString.contains("cookie") || errorString.contains("auth") || errorString.contains("login") {
            return "Authentication required. Please check your browser cookies settings."
        }
        
        // Age restriction/private video
        if errorString.contains("age") || errorString.contains("restrict") || errorString.contains("private") {
            return "This video is restricted or private. Browser cookies may be required."
        }
        
        // Update errors
        if errorString.contains("update") {
            return "Update failed. Please try again later or update manually."
        }
        
        // Default message for unknown errors
        return "An unexpected error occurred. Please try again."
    }
    
    // Format error messages for specific operations
    static func formatDownloadError(_ error: Error) -> String {
        let base = userFriendlyMessage(for: error)
        if base == "An unexpected error occurred. Please try again." {
            return "Download failed. Please check the URL and try again."
        }
        return base
    }
    
    static func formatMetadataError(_ error: Error) -> String {
        let base = userFriendlyMessage(for: error)
        if base == "An unexpected error occurred. Please try again." {
            return "Unable to fetch video information. Please check the URL."
        }
        return base
    }
    
    static func formatPlaylistError(_ error: Error) -> String {
        let base = userFriendlyMessage(for: error)
        if base == "An unexpected error occurred. Please try again." {
            return "Unable to load playlist. It may be private or invalid."
        }
        return base
    }
    
    static func formatUpdateError(_ error: Error) -> String {
        let base = userFriendlyMessage(for: error)
        if base == "An unexpected error occurred. Please try again." {
            return "Update check failed. Please check your internet connection."
        }
        return base
    }
}
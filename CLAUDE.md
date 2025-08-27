# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

yt-dlp-MAX is a native macOS application built with Swift and SwiftUI that provides a user-friendly GUI for yt-dlp video downloading. The app follows the VLC model: simple for beginners, powerful when needed.

## Architecture

**MVVM Pattern:**
- **Models/** - Data structures (VideoInfo, DownloadTask, VideoFormat)
- **Services/** - Business logic (YTDLPService handles yt-dlp process management)
- **Views/** - SwiftUI components (ContentView, VideoInfoView)
- **ViewModels** - State management between Views and Services (to be implemented)

**Key Components:**
- `YTDLPService`: Core service that interfaces with yt-dlp binary
  - Auto-detects yt-dlp installation locations
  - Handles process execution and output parsing
  - Manages download tasks and progress tracking
- `DownloadTask`: Observable class tracking individual download state
- `VideoInfo/VideoFormat`: Codable structs for yt-dlp JSON metadata

## Development Commands

**Build and Run:**
```bash
# Open project in Xcode
open yt-dlp-MAX.xcodeproj

# Build from command line (requires full Xcode installation)
xcodebuild -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX build
```

**Testing:**
```bash
# Run unit tests
xcodebuild test -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX

# Run UI tests
xcodebuild test -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAXUITests
```

## Key Implementation Details

**yt-dlp Integration:**
- The app dynamically searches for yt-dlp in common installation paths
- Supports Homebrew installations (both Intel and Apple Silicon paths)
- Falls back to `which` command if not found in standard locations
- Communicates via Process class with JSON output parsing

**Current Features:**
- URL input with metadata fetching
- Video format selection with quality labels
- Download progress tracking with real-time updates
- Automatic audio/video merging when needed
- Browser cookie support (planned)

**Swift Patterns Used:**
- `@Published` and `@State` for reactive UI updates
- `async/await` for asynchronous operations
- `Codable` for JSON serialization
- `ObservableObject` for shared state management

## Project Status

Currently in Phase 1 development focusing on core downloading functionality. The app can:
- Fetch video metadata from URLs
- Display available formats
- Download videos with progress tracking
- Handle format merging (video + audio)

## Important Notes

- The app requires yt-dlp to be installed (`brew install yt-dlp`)
- Targets macOS with SwiftUI minimum deployment
- Uses entitlements for network access and file system operations
- No external Swift packages currently - pure SwiftUI/Foundation implementation

## Coding Standards

### Comment Future/Unused Code
**ALWAYS** comment code that is placeholder for future features:
- Use `// FUTURE: [Phase/Stage] - Description` for future features
- Use `// Integration point for [feature]` for integration points
- Use `// API: Will be exposed as [endpoint]` for future API endpoints
- Use `// TODO: [task]` for pending implementation tasks
- **NEVER** leave unexplained empty functions or disabled UI elements

Example:
```swift
Button("Add Metadata") {
    // FUTURE: Phase 5 - Manual metadata editing
    // Will allow users to edit title, description, tags
    // Integration point for semansex metadata enrichment
}
.disabled(true)
```

This ensures code maintainability and makes the development roadmap clear to all contributors.
# Fetcha v0.9.0 - Major History & File Management Update

## Version Information
- **Date**: September 5, 2025
- **Version**: 0.9.0
- **Build**: macOS 15.5+ compatible
- **Original Name**: yt-dlp-MAX

## Key Features Implemented

### Core Functionality
- ✅ Full yt-dlp integration with auto-detection
- ✅ Video metadata fetching and format selection
- ✅ Download queue with concurrent downloads (configurable 1-10)
- ✅ Real-time progress tracking with speed and ETA
- ✅ Drag-and-drop queue reordering
- ✅ Download history tracking

### User Interface
- ✅ Modern SwiftUI design with sidebar navigation
- ✅ Collapsible panels (Queue, Details, Debug)
- ✅ Resizable panes with memory
- ✅ Enhanced queue view with automatic sorting:
  - Currently downloading at top
  - Waiting items next
  - Completed items at bottom
- ✅ Context menus for all queue items
- ✅ Single-pane and multi-pane modes

### Advanced Features
- ✅ Post-processing with ffmpeg
  - Container format conversion (MP4, MKV, MOV, WebM, AVI, FLV)
  - Automatic format optimization
  - Optional original file preservation
- ✅ Format fallback handling
  - Automatic alternative format selection
  - Manual format override on errors
- ✅ Cookie support for authenticated downloads
- ✅ Playlist handling with customizable limits
- ✅ Filename templating and sanitization
- ✅ Separate download locations for audio/video

### New in v0.9.0
- ✅ **Complete History Feature Overhaul**
  - History items now have full feature parity with queue items
  - Added "Open in Browser" and "Copy Source URL" buttons
  - Shows actual filename instead of just directory
  - Complete context menu with all queue features
- ✅ **Fixed File Opening/Revealing Issues**
  - Properly opens and reveals actual downloaded files
  - No longer opens directories when trying to play files
  - Smart file discovery finds files even if moved within directory
- ✅ **Enhanced File Discovery System**
  - Uses title keyword matching (first 3 words)
  - Sorts by creation date for most recent files
  - Falls back to most recent media file if no title match
  - Handles special characters in titles properly
- ✅ **Thumbnail Preservation**
  - History now stores and displays video thumbnails
  - Thumbnails persist across app restarts
- ✅ **Improved Media Playback**
  - MediaControlBar properly plays files from history
  - Shows actual filename below title
  - Robust error handling for missing files
- ✅ **Backward Compatibility**
  - Existing history records continue to work without migration
  - Intelligent file search works with old history entries

### Fixed in v0.3.1
- ✅ File selection now works in History panel
- ✅ Play button opens actual files instead of just showing in Finder
- ✅ Media controls maintain independent state from queue selection
- ✅ Completed counter shows actual count instead of hardcoded "30"
- ✅ Dock Quick Actions properly open files with smart fallback
- ✅ Added MediaSelectionCoordinator for better state management

### New in v0.3.0
- ✅ Quick Actions Dock menu showing last 30 downloads
- ✅ Batch URL import from text/CSV files
- ✅ RSS feed import with preview and selection
- ✅ Quick-add to queue with paused downloads option
- ✅ Media control toolbar (play/pause/stop/prev/next)
- ✅ Enhanced error messages with recovery suggestions
- ✅ Improved debug console with filtering and export
- ✅ Fixed History panel filtering (Completed/Failed/In Progress)

### Recent Fixes (v0.2.0)
- ✅ "Show in Finder" reveals actual downloaded files
- ✅ "Open File" properly launches with default media player
- ✅ Failed downloads can reveal partial files in Finder
- ✅ Queue auto-refreshes on status changes
- ✅ File path tracking for post-processed files

### Preferences System
- General settings (download paths, quality defaults)
- Naming templates with preview
- Post-processing configuration
- Update checking for yt-dlp and ffmpeg
- Debug console with comprehensive logging

## Technical Stack
- **Language**: Swift 5
- **UI Framework**: SwiftUI
- **Target**: macOS 15.5+
- **Architecture**: MVVM
- **Dependencies**: 
  - yt-dlp (external, auto-detected)
  - ffmpeg (optional, for post-processing)

## Build Instructions
1. Open `yt-dlp-MAX.xcodeproj` in Xcode
2. Select "yt-dlp-MAX" target
3. Build and run (⌘+R)

## Known Issues
- None critical at RC1 stage

## Future Enhancements
- Browser extension integration
- Cloud storage support
- Advanced metadata editing
- Scheduling and automation
- Multi-language subtitle support

---
*This is a release candidate build ready for production use.*
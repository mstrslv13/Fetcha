# Thumbnail, Privacy, and History Management Enhancements

**Date**: 2025-09-05
**Version**: 0.9.0
**Component**: Multiple (YTDLPService, AppPreferences, DownloadHistory, UI)

## Summary
This update addresses three major issues and feature requests:
1. Fixed thumbnail preservation and display issues
2. Implemented comprehensive history management with auto-clear functionality
3. Added Private Instance Mode for privacy-conscious users

## Changes Made

### 1. Thumbnail Handling Improvements

#### YTDLPService.swift
- Added `--write-thumbnail` flag to yt-dlp arguments to save thumbnails separately
- Added `--add-metadata` flag for better metadata preservation
- Implemented `findThumbnailFile()` helper function to locate downloaded thumbnail files
- Modified download completion to search for and store local thumbnail paths
- Enhanced thumbnail embedding with proper ffmpeg postprocessor arguments

#### VideoDetailsPanel.swift
- Updated `AsyncThumbnailView` to handle both local file paths and remote URLs
- Added support for loading thumbnails from local filesystem

### 2. History Management Features

#### AppPreferences.swift
- Added `historyAutoClear` setting with options: never, 1, 7, 30, 90 days
- Added `historyAutoClearOptions` dictionary for UI display
- Integrated history settings into preferences reset

#### DownloadHistory.swift
- Added `performAutoClear()` method to automatically clear old history on startup
- Enhanced `clearHistory()` with optional confirmation parameter
- Modified constructor to call auto-clear on initialization
- Made `loadHistory()` public to allow reload from UI

#### PreferencesView.swift
- Added new "Privacy" section in preferences sidebar
- Created comprehensive `PrivacyPreferencesView` with:
  - History item count display
  - Auto-clear interval selector
  - Manual clear buttons with confirmation
  - Clean up deleted files function
  - Apply auto-clear now button

### 3. Private Instance Mode

#### AppPreferences.swift
- Added `privateMode` toggle setting
- Added `privateDownloadPath` for separate download location in private mode
- Added `privateModeShowIndicator` to control visual indicators
- Modified `resolvedDownloadPath` to use private path when in private mode

#### DownloadHistory.swift
- Modified `addToHistory()` to skip saving when in private mode
- Updated `loadHistory()` to use separate history file for private mode
- Modified `saveHistory()` to prevent saving in private mode
- Added support for `private_history.json` file

#### ContentView.swift
- Added visual indicator banner when private mode is active
- Shows lock shield icon and "Private Mode Active" text
- Displays "History not saved" message

#### yt_dlp_MAXApp.swift
- Modified window title to show "(Private)" suffix when in private mode
- Added preferences state object to track private mode status

### 4. UI Enhancements

#### PrivacyPreferencesView
Created a comprehensive privacy settings interface with:
- **Private Mode Section**: Toggle, separate download path, indicator settings
- **History Management Section**: Item count, auto-clear settings, manual actions
- **Media Metadata Section**: Thumbnail embedding options

## Technical Implementation Details

### Thumbnail Storage
- Thumbnails are now written to disk alongside video files
- Supported formats: jpg, jpeg, png, webp
- Checks for both `filename.ext` and `filename.thumbnail.ext` patterns
- Local paths stored in history for reliable access

### Private Mode Architecture
- Separate history file (`private_history.json`) for private sessions
- Preferences persist between sessions but are isolated from normal mode
- Visual indicators can be toggled independently
- Download location can be customized for private mode

### History Auto-Clear Logic
- Runs on app startup
- Filters records based on timestamp comparison
- Preserves recent items while removing old ones
- Can be triggered manually from preferences

## Testing Recommendations

1. **Thumbnail Testing**
   - Download a video and verify thumbnail appears in queue/history
   - Restart app and confirm thumbnails persist
   - Test with different video sources

2. **History Management Testing**
   - Set auto-clear to 1 day, add old items, verify cleanup
   - Test manual clear with confirmation dialog
   - Verify "Clean Up Deleted Files" removes orphaned entries

3. **Private Mode Testing**
   - Enable private mode and verify no history is saved
   - Test separate download location
   - Verify visual indicators appear correctly
   - Confirm window title shows "(Private)" suffix

## Known Limitations

- Thumbnails from some sources may not be available
- Private mode history is completely ephemeral (not saved at all)
- Auto-clear runs only on startup, not continuously

## Future Enhancements

- Cache thumbnails locally for faster loading
- Add scheduled auto-clear (not just on startup)
- Implement separate private mode preferences for more settings
- Add option to convert history to private retroactively
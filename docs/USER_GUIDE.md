# fetcha.stream User Guide

Welcome to the complete user guide for fetcha.stream (yt-dlp-MAX). This guide will walk you through every feature of the application, from basic downloads to advanced power-user features.

## Table of Contents

- [Getting Started](#getting-started)
- [Interface Overview](#interface-overview)
- [Downloading Videos](#downloading-videos)
- [Format Selection](#format-selection)
- [Queue Management](#queue-management)
- [Preferences & Settings](#preferences--settings)
- [Preset Management](#preset-management)
- [Browser Cookie Support](#browser-cookie-support)
- [Advanced Features](#advanced-features)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Tips & Tricks](#tips--tricks)

## Getting Started

### First Launch

When you first open fetcha.stream, you'll see:

1. **Main Window** - Clean interface with URL input field
2. **Preferences Prompt** - Set your default download location
3. **Cookie Permission** - Optional: Allow browser cookie access for private videos

### Basic Workflow

The simplest way to use fetcha.stream:

1. **Copy** a video URL from your browser
2. **Open** fetcha.stream (it automatically detects the URL)
3. **Press Enter** or click Download
4. **Watch** the progress bar as your video downloads

Your video is saved to the Downloads folder (or your chosen location).

## Interface Overview

### Main Window Components

```
┌─────────────────────────────────────────────────────┐
│  fetcha.stream                            [⚙️] [🐞]  │
├─────────────────────────────────────────────────────┤
│  Preset: [⭐ Default]                     [Presets ▼]│
├─────────────────────────────────────────────────────┤
│  [URL Input Field........................] [Get Info]│
│                                          [Download ▼]│
├─────────────────────────────────────────────────────┤
│  Download Queue                                      │
│  ┌─────────────────────────────────────────────────┐│
│  │ 📹 Video Title 1          [=====>    ] 45%      ││
│  │ 📹 Video Title 2          [Waiting...]          ││
│  │ 📹 Video Title 3          [Queued]              ││
│  └─────────────────────────────────────────────────┘│
├─────────────────────────────────────────────────────┤
│  Status: Downloading 1 of 3 videos...               │
└─────────────────────────────────────────────────────┘
```

### Interface Elements

#### Top Bar
- **App Title**: fetcha.stream branding
- **Queue Progress**: Overall download progress when active
- **Settings Button** (⚙️): Opens Preferences
- **Debug Button** (🐞): Opens debug console (if enabled)

#### Preset Bar
- **Active Preset Indicator**: Shows current preset with icon
- **Preset Menu**: Quick access to saved presets
- **Manage Presets**: Create and edit preset configurations

#### Input Section
- **URL Field**: Paste or type video URLs here
- **Get Info Button**: Fetch video metadata without downloading
- **Download Button**: Start download with dropdown for format options

#### Queue Panel
- **Download List**: All queued, active, and completed downloads
- **Progress Bars**: Real-time download progress
- **Item Status**: Current state of each download
- **Context Menu**: Right-click for item options

#### Status Bar
- **Activity Indicator**: Current operation status
- **Message Area**: Helpful tips and error messages

## Downloading Videos

### Single Video Download

#### Method 1: Quick Download
1. Copy video URL from browser
2. Open fetcha.stream (URL auto-populates)
3. Press **Enter** or click **Download**

#### Method 2: Choose Quality First
1. Paste URL in the input field
2. Click **Get Info** to fetch available formats
3. Select desired quality from dropdown
4. Click **Download**

#### Method 3: Drag and Drop
1. Drag video URL from browser address bar
2. Drop onto fetcha.stream window
3. Download starts automatically (if auto-queue enabled)

### Playlist Downloads

When you paste a playlist URL:

1. **Playlist Detection**: App recognizes it's a playlist
2. **Confirmation Dialog**: Shows number of videos found
3. **Options**:
   - Download all videos
   - Select specific videos
   - Set quality for all items
4. **Queue Addition**: Videos added to download queue
5. **Sequential Processing**: Downloads in order

### Channel Downloads

For downloading entire channels:

1. Paste channel URL
2. App detects channel and shows video count
3. Choose download options:
   - Latest videos only
   - Date range
   - Video count limit
4. Videos are queued for download

## Format Selection

### Understanding Formats

Videos are available in different formats:

- **Resolution**: 4K, 1080p, 720p, 480p, 360p
- **Codec**: H.264 (compatibility), H.265 (smaller files), VP9, AV1
- **Container**: MP4 (universal), MKV (features), WEBM (web)
- **Audio**: AAC, MP3, Opus, Vorbis

### Quick Format Selection

Use the dropdown menu next to Download:

- **Best Quality**: Highest available resolution and bitrate
- **1080p**: Full HD, good balance of quality and size
- **720p**: HD, smaller files, faster downloads
- **Audio Only**: Extract just the audio track
- **Custom**: Choose specific format code

### Advanced Format Selection

After clicking **Get Info**:

```
Available Formats:
┌──────┬────────────┬──────────┬────────┬──────────┐
│ Code │ Resolution │ Extension│ Size   │ Note     │
├──────┼────────────┼──────────┼────────┼──────────┤
│ 137  │ 1080p      │ mp4      │ 245 MB │ video    │
│ 140  │ audio      │ m4a      │ 12 MB  │ audio    │
│ 22   │ 720p       │ mp4      │ 95 MB  │ combined │
└──────┴────────────┴──────────┴────────┴──────────┘
```

**Format Types**:
- **Combined**: Video + Audio in one file (easiest)
- **Video Only**: Requires merging with audio
- **Audio Only**: Just the audio track

### Format Merging

When selecting video-only formats:

1. App automatically selects best matching audio
2. Downloads both streams
3. Merges them using ffmpeg
4. Deletes source files (unless "Keep Original" is enabled)

## Queue Management

### Queue Operations

#### Adding to Queue
- **Auto-Queue**: Enable in Preferences for automatic queuing
- **Manual Add**: Click dropdown arrow → "Add to Queue"
- **Batch Add**: Paste multiple URLs separated by newlines

#### Queue Controls
- **Start/Pause All**: Control entire queue
- **Reorder**: Drag items to change order
- **Priority**: Right-click → "Download Next"
- **Remove**: Select and press Delete key

#### Item States
- **Queued**: Waiting to download
- **Waiting**: Next in line
- **Downloading**: Currently active
- **Processing**: Merging or converting
- **Completed**: Successfully downloaded
- **Failed**: Error occurred (can retry)
- **Paused**: Manually paused

### Queue Settings

Access via Preferences → Queue:

- **Max Concurrent Downloads**: 1-10 simultaneous downloads
- **Auto-Start**: Begin downloads immediately when added
- **Continue on Error**: Don't stop queue if one fails
- **Auto-Retry Failed**: Retry failed downloads automatically
- **Retry Attempts**: Number of retry attempts (1-10)

### Queue Context Menu

Right-click any queue item:

- **Pause/Resume**: Control individual download
- **Download Next**: Move to front of queue
- **Remove from Queue**: Delete from list
- **Retry**: Try downloading again
- **Show in Finder**: Open download location
- **Copy URL**: Copy original video URL
- **View Details**: Show format and metadata

## Preferences & Settings

### General Preferences

#### Download Locations
- **Default Location**: Primary save folder
- **Use Separate Locations**: Different folders by type
  - Audio downloads
  - Video-only downloads
  - Merged files

#### Behavior
- **Auto-add to Queue**: Queue URLs immediately
- **Skip Metadata Fetch**: Faster queuing, no preview
- **Auto-paste Clipboard**: Detect URLs automatically
- **Single Pane Mode**: Compact interface

### Download Preferences

#### Quality Settings
- **Default Video Quality**: Automatic quality selection
  - Best available
  - Specific resolution (4K, 1080p, 720p, etc.)
  - Best under size limit
- **Prefer 60fps**: Choose higher framerate when available
- **Prefer Free Formats**: Open codecs (VP9, AV1)

#### Audio Settings
- **Output Separate Audio**: Save audio file alongside video
- **Audio Format**: MP3, AAC, FLAC, WAV, Opus
- **Audio Quality**: Bitrate selection (128-320 kbps)

#### File Handling
- **File Overwrite Mode**:
  - Skip existing files
  - Overwrite always
  - Resume partial downloads
- **Keep Original Files**: Don't delete after merging
- **Restrict Filenames**: Windows-compatible names

### Advanced Preferences

#### Network
- **Rate Limit**: Maximum download speed (KB/s)
- **Concurrent Fragments**: Parallel connections (1-10)
- **Socket Timeout**: Connection timeout (seconds)
- **Proxy URL**: HTTP/SOCKS proxy settings
- **Force IPv4/IPv6**: IP version preference

#### Cookie Settings
- **Cookie Source**: Browser selection
  - None (no cookies)
  - Safari
  - Chrome
  - Firefox
  - Brave
  - Edge
- **Auto-refresh Cookies**: Update before each download

#### Metadata & Subtitles
- **Embed Metadata**: Include video information
- **Embed Thumbnail**: Add cover image to file
- **Download Subtitles**: Get available captions
- **Subtitle Languages**: Comma-separated language codes
- **Convert Subtitles**: Output format (SRT, VTT, ASS)

#### File Naming
- **Naming Template**: Customize output filenames
  - `%(title)s`: Video title
  - `%(id)s`: Video ID
  - `%(uploader)s`: Channel name
  - `%(upload_date)s`: Upload date
  - `%(resolution)s`: Video resolution
  - `%(ext)s`: File extension

**Example Templates**:
- Default: `%(title)s.%(ext)s`
- Organized: `%(uploader)s/%(upload_date)s - %(title)s.%(ext)s`
- Unique: `%(title)s [%(id)s].%(ext)s`

#### Performance
- **Max Concurrent Downloads**: Queue parallelism (1-10)
- **Fragment Retries**: Retry count for segments
- **Throttle Rate**: Minimum speed before retry
- **HTTP Chunk Size**: Download chunk size

## Preset Management

### Understanding Presets

Presets save your favorite settings combinations:

- Quick access to different download configurations
- Switch between quality/speed/compatibility modes
- Share settings with other users

### Built-in Presets

#### Best Quality
- Maximum resolution available
- Best audio quality
- Larger file sizes
- Slower downloads

#### Balanced
- 1080p video
- Good audio quality
- Reasonable file sizes
- Faster downloads

#### Quick Download
- 720p video
- Standard audio
- Smaller files
- Fastest downloads

#### Audio Only
- Extract audio track
- MP3 format
- Smallest files
- Music/podcast focus

### Creating Custom Presets

1. Click **Presets → Manage Presets**
2. Click **+** to create new preset
3. Configure settings:
   - Name and icon
   - Video quality
   - Audio settings
   - Download behavior
   - File naming
4. Click **Save**

### Using Presets

#### Quick Switch
- Click preset dropdown in main window
- Select desired preset
- Settings apply immediately

#### Temporary Override
- Select preset as base
- Modify settings for current session
- Changes don't affect saved preset

#### Keyboard Shortcuts
- **⌘+1** through **⌘+9**: Quick preset selection
- **⌘+0**: Default preset

## Browser Cookie Support

### Why Use Cookies?

Cookies allow downloading:
- Private videos requiring login
- Age-restricted content
- Subscription/member-only videos
- Region-locked content (with your account)

### Setting Up Cookie Support

1. **Login to Website**: Use your browser normally
2. **Open Preferences**: fetcha.stream → Preferences
3. **Select Browser**: Choose from Cookie Source dropdown
4. **Grant Permission**: Allow fetcha.stream to read cookies
5. **Test**: Try downloading a private video

### Supported Browsers

#### Safari
- Default Mac browser
- Automatic detection
- No additional setup

#### Chrome
- Most popular browser
- Supports multiple profiles
- Select active profile

#### Firefox
- Privacy-focused browser
- Separate container support
- Multiple profile support

#### Brave
- Chrome-based with privacy
- Similar to Chrome setup
- Ad-blocker compatible

#### Edge
- Microsoft browser
- Chrome-based engine
- Windows compatibility

### Cookie Troubleshooting

**"No cookies found"**
- Ensure you're logged into the website
- Try refreshing the page in browser
- Clear and re-login to website

**"Access denied"**
- Grant permission in System Preferences
- Check Security & Privacy settings
- Restart fetcha.stream

**"Invalid cookies"**
- Cookies may have expired
- Log out and back into website
- Try different browser

## Advanced Features

### Download History

Track all your downloads:

- **View History**: Window → Download History
- **Search**: Find previous downloads
- **Re-download**: Queue again with same settings
- **Statistics**: Download counts and sizes

### Debug Console

For troubleshooting:

1. Enable in Preferences → Advanced
2. Click bug icon in toolbar
3. View detailed logs:
   - yt-dlp output
   - Error messages
   - Network activity
   - Process information

### Scheduled Downloads

Plan downloads for later:

1. Add videos to queue
2. Right-click → Schedule
3. Set date and time
4. fetcha.stream must remain open

### Post-Processing

After download completes:

- **Convert Format**: Change container/codec
- **Extract Audio**: Create separate audio file
- **Compress**: Reduce file size
- **Custom Scripts**: Run your own commands

### URL Patterns

Advanced URL handling:

- **Batch URLs**: Multiple URLs in one paste
- **URL Lists**: Import from text file
- **Patterns**: Download videos matching criteria
- **Exclusions**: Skip certain videos

## Keyboard Shortcuts

### Essential Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘+V** | Paste URL and auto-add |
| **⌘+⏎** | Start download |
| **Space** | Pause/Resume selected |
| **Delete** | Remove from queue |
| **⌘+,** | Open Preferences |
| **⌘+Q** | Quit application |

### Queue Management

| Shortcut | Action |
|----------|--------|
| **↑/↓** | Navigate queue |
| **⌘+↑** | Move item up |
| **⌘+↓** | Move item down |
| **⌘+A** | Select all items |
| **⌘+D** | Deselect all |
| **⌘+R** | Retry failed item |

### Window Management

| Shortcut | Action |
|----------|--------|
| **⌘+1** | Show main window |
| **⌘+2** | Show queue window |
| **⌘+3** | Show history |
| **⌘+M** | Minimize window |
| **⌘+W** | Close window |
| **⌘+F** | Search in queue |

### Advanced Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘+⇧+D** | Debug console |
| **⌘+⇧+P** | Preset manager |
| **⌘+⇧+C** | Copy download command |
| **⌘+⇧+L** | View download log |
| **⌘+⇧+S** | Export queue |

## Tips & Tricks

### Performance Tips

1. **Concurrent Downloads**: Balance speed vs. stability
   - 1-2 for slow connections
   - 3-5 for fast connections
   - More may cause throttling

2. **Fragment Settings**: Optimize chunk downloads
   - Increase for fast connections
   - Decrease for unstable connections
   - Default (5) works for most

3. **Cache Usage**: Let fetcha.stream cache metadata
   - Faster re-downloads
   - Quick format checking
   - Reduced API calls

### Quality vs. Size

**For Best Quality**:
- Select highest resolution
- Choose original format
- Keep original codec
- Enable metadata embedding

**For Smaller Files**:
- Choose 720p or lower
- Select H.265/HEVC codec
- Use MP4 container
- Disable thumbnail embedding

**For Compatibility**:
- Select MP4 format
- Use H.264 codec
- Choose AAC audio
- Avoid 4K/60fps

### Organization Tips

1. **Folder Structure**:
   ```
   Downloads/
   ├── Videos/
   │   ├── YouTube/
   │   ├── Tutorials/
   │   └── Music/
   ├── Audio/
   └── Temp/
   ```

2. **Naming Conventions**:
   - Include date for sorting
   - Add channel name for grouping
   - Use video ID for uniqueness

3. **Preset Strategy**:
   - Create preset per use case
   - Name clearly (Music, Archive, Quick)
   - Set appropriate quality/format

### Batch Processing

**Downloading Playlists**:
1. Enable "Continue on Error"
2. Set retry attempts to 3
3. Use consistent quality
4. Monitor first few downloads

**Channel Archives**:
1. Use date filters
2. Set max downloads limit
3. Create channel folder
4. Include metadata

**URL Lists**:
1. Prepare URLs in text file
2. One URL per line
3. Copy all and paste
4. Queue processes automatically

### Troubleshooting Process

When downloads fail:

1. **Check URL**: Ensure it's valid and accessible
2. **Try Browser**: Can you view it normally?
3. **Check Cookies**: Refresh if private video
4. **View Debug**: See exact error message
5. **Try Different Format**: Some formats may be broken
6. **Update App**: Check for newer version
7. **Report Issue**: If persistent problem

### Privacy & Security

**Protect Your Privacy**:
- Don't share cookie files
- Use separate browser profile
- Clear history regularly
- Disable telemetry in preferences

**Secure Downloads**:
- Verify source websites
- Check file sizes
- Scan downloads
- Use trusted networks

## Getting Help

### In-App Help
- Hover over any setting for tooltip
- Click **?** icons for explanations
- Check status bar for hints

### Online Resources
- [FAQ](FAQ.md) - Common questions
- [Troubleshooting](TROUBLESHOOTING.md) - Problem solutions
- [GitHub Issues](https://github.com/yourusername/fetcha-stream/issues) - Bug reports
- [Discussions](https://github.com/yourusername/fetcha-stream/discussions) - Community help

### Contact Support
- Email: support@fetcha.stream
- Twitter: @fetchastream
- Discord: [Join Server]

---

Thank you for using fetcha.stream! We hope this guide helps you get the most out of the application. If you have suggestions for improving this documentation, please let us know.
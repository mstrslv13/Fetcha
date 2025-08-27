# fetcha.stream Features Documentation

Complete documentation of all features available in fetcha.stream (yt-dlp-MAX).

## Table of Contents

- [Core Features](#core-features)
- [Download Queue](#download-queue)
- [Format Selection](#format-selection)
- [Browser Cookie Integration](#browser-cookie-integration)
- [File Management](#file-management)
- [Preset System](#preset-system)
- [Progress Tracking](#progress-tracking)
- [Network Features](#network-features)
- [Metadata & Subtitles](#metadata--subtitles)
- [Advanced Options](#advanced-options)
- [User Interface](#user-interface)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Debug & Troubleshooting](#debug--troubleshooting)

## Core Features

### One-Click Downloads

The simplest way to download videos with zero configuration required.

**How it works**:
1. Copy any video URL to clipboard
2. Open fetcha.stream (URL auto-populates)
3. Press Enter or click Download
4. Video saves to your Downloads folder

**Features**:
- Automatic URL detection from clipboard
- Smart format selection (best quality by default)
- Real-time progress tracking
- Automatic file naming

**When to use**:
- Quick downloads without customization
- Testing if a video can be downloaded
- Simple archiving tasks

### Smart URL Detection

Intelligently identifies and processes various URL types.

**Supported URL types**:
- Direct video URLs
- Playlist URLs (with confirmation)
- Channel URLs (with options)
- Shortened URLs (auto-expands)
- Mobile URLs (converts to desktop)
- Timestamp URLs (preserves position)

**Features**:
- Automatic clipboard monitoring
- URL validation before processing
- Duplicate detection
- Batch URL processing (paste multiple)

### Automatic Quality Selection

Intelligently chooses the best format without user intervention.

**Selection criteria**:
1. Highest available resolution
2. Best codec for compatibility
3. Optimal file size balance
4. Hardware compatibility check

**Smart features**:
- Falls back to lower quality if best fails
- Prefers pre-merged formats for speed
- Avoids formats requiring conversion
- Considers available disk space

## Download Queue

### Queue Management

Powerful queue system for handling multiple downloads efficiently.

**Core capabilities**:
- Unlimited queue size
- Drag-and-drop reordering
- Priority management
- Batch operations

**Queue operations**:
- **Add**: Paste URL or use "Add to Queue"
- **Remove**: Select and press Delete
- **Reorder**: Drag items up/down
- **Prioritize**: Right-click → "Download Next"
- **Clear**: Remove completed/failed items

### Concurrent Downloads

Download multiple videos simultaneously for faster batch processing.

**Configuration**:
- Set 1-10 concurrent downloads
- Automatic bandwidth distribution
- Smart server detection (avoids overloading)
- Per-site concurrent limits

**Optimization**:
- Adjusts based on connection speed
- Reduces concurrent for same site
- Increases for different sites
- Monitors for throttling

### Queue Persistence

Queue state is maintained across app sessions.

**Persistent data**:
- Queue contents and order
- Download progress
- Item status
- Retry counters

**Recovery features**:
- Resume after app restart
- Restore after crash
- Continue after sleep/wake
- Rebuild from partial data

### Queue Filtering & Search

Find and manage items in large queues.

**Filter options**:
- Status (queued, downloading, completed, failed)
- Source site
- Quality/format
- Date added

**Search capabilities**:
- Title search
- URL search
- Channel/uploader
- Fuzzy matching

### Batch Operations

Perform actions on multiple queue items at once.

**Batch actions**:
- Select all/none
- Remove selected
- Retry failed items
- Change quality for multiple
- Export selected URLs

## Format Selection

### Interactive Format Picker

Visual interface for choosing exact video format.

**Information displayed**:
- Resolution (4K, 1080p, 720p, etc.)
- File size estimate
- Codec (H.264, VP9, AV1)
- Container (MP4, MKV, WebM)
- Bitrate
- FPS (frames per second)
- HDR availability

**Selection modes**:
- **Simple**: Choose by resolution
- **Advanced**: Select specific format codes
- **Custom**: Enter format string directly

### Format Merging

Automatically combines separate video and audio streams.

**Process**:
1. Downloads video stream
2. Downloads matching audio stream
3. Merges with ffmpeg
4. Cleans up source files

**Options**:
- Keep original streams
- Choose merge container
- Select audio quality
- Priority order for formats

### Audio Extraction

Download only the audio track from videos.

**Audio formats supported**:
- MP3 (most compatible)
- AAC (Apple devices)
- FLAC (lossless)
- WAV (uncompressed)
- Opus (efficient)
- Vorbis (open)
- M4A (iTunes compatible)

**Features**:
- Automatic best quality selection
- Bitrate configuration
- Metadata preservation
- Album art embedding

### Quality Presets

Pre-configured quality settings for common use cases.

**Built-in presets**:

| Preset | Resolution | Codec | Use Case |
|--------|------------|-------|----------|
| Best | Maximum | Any | Archiving |
| 4K | 2160p | H.265 preferred | 4K displays |
| Full HD | 1080p | H.264 | General use |
| HD | 720p | H.264 | Balanced |
| SD | 480p | H.264 | Low bandwidth |
| Audio | N/A | MP3/AAC | Music/podcasts |

### Format Compatibility

Ensures downloaded videos work on your devices.

**Compatibility modes**:
- **Universal**: MP4/H.264/AAC (works everywhere)
- **Apple**: Optimized for Mac/iOS
- **Modern**: H.265/VP9 for newer devices
- **Web**: WebM for browsers

**Auto-detection**:
- Checks system capabilities
- Suggests compatible formats
- Warns about compatibility issues

## Browser Cookie Integration

### Automatic Cookie Extraction

Seamlessly use browser cookies for authenticated downloads.

**Supported browsers**:
- Safari (native integration)
- Chrome (all profiles)
- Firefox (all profiles)
- Brave (privacy-preserved)
- Edge (Windows compatible)

**How it works**:
1. Reads browser cookie database
2. Extracts relevant cookies
3. Passes to download engine
4. Cleans up after use

### Multi-Browser Support

Switch between different browsers for different sites.

**Use cases**:
- Different accounts in different browsers
- Site-specific browser requirements
- Privacy separation
- Testing/debugging

**Features**:
- Quick browser switching
- Per-download browser selection
- Browser profile support
- Cookie refresh capability

### Secure Cookie Handling

Protects your authentication data.

**Security measures**:
- Read-only access
- No network transmission
- Temporary memory storage
- Automatic cleanup
- Encrypted transmission to yt-dlp

**Privacy features**:
- No cookie logging
- No persistent storage
- Session isolation
- Secure deletion

### Cookie Troubleshooting Tools

Debug authentication issues easily.

**Diagnostic features**:
- Cookie presence check
- Expiration detection
- Browser detection
- Permission verification

**Solutions provided**:
- Step-by-step fixes
- Browser-specific guides
- Permission instructions
- Refresh procedures

## File Management

### Smart File Naming

Flexible template system for organizing downloads.

**Template variables**:
- `%(title)s` - Video title
- `%(id)s` - Unique video ID
- `%(uploader)s` - Channel/uploader name
- `%(upload_date)s` - Upload date
- `%(duration)s` - Video length
- `%(resolution)s` - Video quality
- `%(ext)s` - File extension
- `%(autonumber)s` - Sequential number

**Example templates**:
```
Default: %(title)s.%(ext)s
→ Amazing Video.mp4

Organized: %(uploader)s/%(upload_date)s - %(title)s.%(ext)s
→ ChannelName/2024-01-15 - Amazing Video.mp4

Unique: [%(id)s] %(title)s.%(ext)s
→ [dQw4w9WgXcQ] Amazing Video.mp4
```

### Multiple Download Locations

Organize downloads by type automatically.

**Separate locations for**:
- Merged videos (final output)
- Video-only streams
- Audio-only files
- Subtitles
- Metadata files
- Thumbnails

**Benefits**:
- Automatic organization
- Easy cleanup
- Type-specific processing
- Storage optimization

### Automatic Folder Creation

Create organized folder structures automatically.

**Folder templates**:
- By channel/uploader
- By date (year/month/day)
- By site
- By playlist
- By quality
- Custom combinations

**Features**:
- Creates missing folders
- Handles special characters
- Windows-safe naming
- Preserves hierarchy

### Download History

Track all your downloaded videos.

**History features**:
- Complete download log
- Search and filter
- Re-download capability
- Statistics dashboard
- Export to CSV/JSON

**Tracked information**:
- URL and title
- Download date/time
- File location
- Format selected
- File size
- Download duration

### Duplicate Prevention

Avoid downloading the same video twice.

**Detection methods**:
- URL matching
- Video ID tracking
- File existence check
- Archive file support

**Options**:
- Skip existing files
- Overwrite always
- Compare file sizes
- Check video IDs only

## Preset System

### Preset Management

Save and organize your favorite download configurations.

**Preset contents**:
- Video quality settings
- Audio preferences
- File naming templates
- Download locations
- Network settings
- Post-processing options

**Management features**:
- Create unlimited presets
- Edit existing presets
- Delete unused presets
- Import/export presets
- Share with others

### Quick Preset Switching

Change settings instantly with presets.

**Access methods**:
- Dropdown menu in main window
- Keyboard shortcuts (⌘+1 through ⌘+9)
- Context menu on URLs
- Automatic based on site

**Use cases**:
- Music downloads (audio only)
- Archiving (maximum quality)
- Quick saves (balanced)
- Mobile transfers (compressed)

### Preset Scheduling

Automatically apply presets based on conditions.

**Conditions**:
- Site/domain
- Time of day
- Network connection
- Disk space
- Queue size

**Examples**:
- Use "Quick" preset on mobile hotspot
- Use "Archive" preset for specific channels
- Use "Audio" preset for music sites

### Preset Import/Export

Share configurations between devices or users.

**Export includes**:
- All settings
- File templates
- Network config
- Quality preferences

**Import options**:
- Replace existing
- Merge with current
- Create as new
- Selective import

## Progress Tracking

### Real-Time Progress Bars

Visual feedback for all download operations.

**Information shown**:
- Percentage complete
- Downloaded/total size
- Current speed
- Time remaining
- Average speed

**Visual indicators**:
- Progress bar fill
- Color coding by status
- Speed graph
- Queue position

### Download Speed Monitoring

Track and optimize download performance.

**Metrics tracked**:
- Current speed (KB/s, MB/s)
- Average speed
- Peak speed
- Speed history graph

**Features**:
- Per-download speeds
- Total bandwidth usage
- Speed limiting warnings
- Throttling detection

### ETA Calculation

Accurate time remaining estimates.

**Calculation factors**:
- Current speed
- Historical speed
- File size remaining
- Queue position
- Concurrent downloads

**Display formats**:
- Seconds/minutes/hours
- Completion time
- Dynamic updates
- Batch ETA

### Queue Progress Overview

Monitor overall queue completion.

**Overview shows**:
- Total items
- Completed count
- Failed count
- Total size
- Time elapsed
- Estimated completion

**Visual elements**:
- Overall progress bar
- Pie chart breakdown
- Status indicators
- Statistics panel

## Network Features

### Bandwidth Management

Control download speeds and network usage.

**Rate limiting**:
- Global speed limit
- Per-download limits
- Time-based limits
- Automatic throttling

**Smart features**:
- Detect available bandwidth
- Adjust for network conditions
- Respect server limits
- Balance multiple downloads

### Proxy Support

Route downloads through proxy servers.

**Proxy types supported**:
- HTTP/HTTPS
- SOCKS4/SOCKS5
- Authenticated proxies
- PAC files

**Configuration**:
- Global proxy settings
- Per-site proxies
- Proxy chains
- Automatic detection

### Connection Management

Optimize network connections for reliability.

**Settings**:
- Connection timeout
- Retry attempts
- Fragment size
- Concurrent connections
- Keep-alive settings

**Recovery features**:
- Automatic reconnection
- Resume on connection restore
- Fallback servers
- Error recovery

### IPv4/IPv6 Support

Control IP version usage.

**Options**:
- Automatic selection
- Force IPv4 only
- Force IPv6 only
- Fallback preferences

**Use cases**:
- ISP compatibility
- Server requirements
- Performance optimization
- Troubleshooting

## Metadata & Subtitles

### Metadata Embedding

Include video information in downloaded files.

**Embedded metadata**:
- Title and description
- Upload date
- Channel/uploader
- Thumbnail
- Chapters
- Comments

**Formats supporting metadata**:
- MP4 (limited)
- MKV (full)
- WebM (partial)

### Subtitle Download

Get captions and subtitles with videos.

**Subtitle features**:
- Download available subtitles
- Auto-generated captions
- Multiple languages
- Format conversion

**Options**:
- Embed in video
- Save separately
- Convert formats (SRT, VTT, ASS)
- Language preferences

### Thumbnail Handling

Manage video preview images.

**Thumbnail options**:
- Embed in video file
- Save separately
- Use as folder icon
- Create collage
- Skip thumbnails

**Formats**:
- JPEG (most compatible)
- PNG (better quality)
- WebP (smaller size)

### Chapter Markers

Preserve video chapters and segments.

**Chapter features**:
- Download chapter info
- Embed in video
- Export to file
- Create separate clips

**Supported in**:
- MKV files
- MP4 (limited)
- External files

### Comment Extraction

Save video comments and discussions.

**Comment options**:
- Download all comments
- Top comments only
- Include replies
- Save as JSON/TXT

**Information saved**:
- Comment text
- Author
- Timestamp
- Likes/votes
- Reply threads

## Advanced Options

### Custom yt-dlp Arguments

Add command-line arguments for advanced control.

**Use cases**:
- Experimental features
- Site-specific options
- Debugging flags
- Unsupported options

**How to use**:
1. Preferences → Advanced
2. Enter arguments in "Custom Arguments"
3. Applied to all downloads
4. Override GUI settings

### Post-Processing Scripts

Run custom scripts after downloads.

**Capabilities**:
- Format conversion
- File organization
- Metadata editing
- Upload to cloud
- Custom notifications

**Script access to**:
- File path
- Video metadata
- Download statistics
- Queue information

### Archive File Support

Track downloaded videos across sessions.

**Archive features**:
- Records video IDs
- Prevents re-downloads
- Portable between systems
- Human-readable format

**Use cases**:
- Channel archiving
- Playlist updates
- Duplicate prevention
- Backup tracking

### Geo-Bypass Options

Access geo-restricted content.

**Methods**:
- Automatic country detection
- Proxy routing
- VPN compatibility
- Custom headers

**Features**:
- Per-site configuration
- Fallback countries
- Error handling
- Legal compliance warnings

### Live Stream Handling

Download live broadcasts and premieres.

**Live options**:
- Download from start
- Join live stream
- Wait for scheduled
- Record duration

**Features**:
- Automatic quality selection
- Connection recovery
- Buffer management
- Post-live processing

## User Interface

### Main Window

Clean, intuitive primary interface.

**Components**:
- URL input field
- Format selector
- Download button
- Queue panel
- Status bar

**Features**:
- Responsive design
- Dark mode support
- Customizable layout
- Keyboard navigation

### Queue Panel

Dedicated area for managing downloads.

**Display modes**:
- Compact (one line per item)
- Detailed (with thumbnails)
- List view
- Grid view

**Information shown**:
- Thumbnail
- Title
- Progress
- Speed
- Status

### Preferences Window

Comprehensive settings interface.

**Organization**:
- Tabbed categories
- Search function
- Reset defaults
- Import/export

**Categories**:
- General
- Downloads
- Network
- Files
- Advanced

### Debug Console

Built-in troubleshooting interface.

**Features**:
- Real-time logs
- Error highlighting
- Command output
- Export logs

**Information shown**:
- yt-dlp output
- Error messages
- Network activity
- System information

### Context Menus

Right-click menus throughout the app.

**Queue item menu**:
- Pause/Resume
- Remove
- Retry
- Show in Finder
- Copy URL
- Change quality

**URL field menu**:
- Paste
- Clear
- Get Info
- Add to Queue

## Keyboard Shortcuts

### Global Shortcuts

Available throughout the application.

| Shortcut | Action |
|----------|--------|
| ⌘+N | New download |
| ⌘+V | Paste URL |
| ⌘+⏎ | Start download |
| ⌘+, | Preferences |
| ⌘+Q | Quit |
| ⌘+W | Close window |
| ⌘+M | Minimize |

### Queue Shortcuts

For managing the download queue.

| Shortcut | Action |
|----------|--------|
| Space | Pause/Resume |
| Delete | Remove item |
| ⌘+A | Select all |
| ⌘+R | Retry failed |
| ↑/↓ | Navigate |
| ⌘+↑/↓ | Reorder |

### Navigation Shortcuts

For moving through the interface.

| Shortcut | Action |
|----------|--------|
| Tab | Next field |
| ⇧+Tab | Previous field |
| ⌘+1-9 | Switch presets |
| ⌘+F | Search queue |
| Esc | Cancel operation |

## Debug & Troubleshooting

### Debug Console

Comprehensive debugging interface.

**Features**:
- Real-time log streaming
- Error highlighting
- Verbose output toggle
- Log filtering

**Information available**:
- Complete yt-dlp output
- Network requests
- Cookie operations
- Process management

### Log Export

Save debugging information for support.

**Export options**:
- Full logs
- Filtered logs
- Time range
- Anonymized

**Formats**:
- Plain text
- JSON
- Compressed archive

### Error Recovery

Automatic handling of common errors.

**Recovery actions**:
- Retry failed downloads
- Resume interrupted
- Fallback formats
- Alternative servers

**Configuration**:
- Retry attempts
- Retry delay
- Error types to retry
- Fallback options

### Performance Monitoring

Track app performance and resource usage.

**Metrics**:
- CPU usage
- Memory usage
- Disk I/O
- Network bandwidth
- Queue processing time

**Optimization suggestions**:
- Reduce concurrent downloads
- Clear history
- Adjust fragment size
- Enable caching

---

This comprehensive feature documentation covers all current and planned capabilities of fetcha.stream. Features are continuously improved based on user feedback and technological advances.
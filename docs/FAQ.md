# Frequently Asked Questions (FAQ)

Quick answers to common questions about fetcha.stream (yt-dlp-MAX).

## Table of Contents

- [General Questions](#general-questions)
- [Download Questions](#download-questions)
- [Video Quality & Formats](#video-quality--formats)
- [Browser & Cookies](#browser--cookies)
- [File Management](#file-management)
- [Performance & Speed](#performance--speed)
- [Compatibility](#compatibility)
- [Privacy & Security](#privacy--security)
- [Troubleshooting](#troubleshooting)
- [Advanced Features](#advanced-features)

## General Questions

### What is fetcha.stream?

fetcha.stream is a native macOS application that provides a user-friendly interface for downloading videos from YouTube and 1000+ other websites. It's built on top of yt-dlp, the powerful command-line tool, but requires no technical knowledge to use.

### Is fetcha.stream free?

Yes, fetcha.stream is completely free and open source. There are no hidden costs, subscriptions, or premium features. The source code is available on GitHub under the MIT license.

### What makes fetcha.stream different from other downloaders?

Key differentiators:
- **Native macOS app**: Built specifically for Mac, not a web wrapper
- **Browser cookie support**: One-click access to private/subscription videos
- **Queue management**: Download multiple videos efficiently
- **No dependencies**: Everything needed is included
- **Privacy focused**: No data collection or ads
- **Open source**: Fully auditable and trustworthy

### Do I need to install yt-dlp separately?

No! fetcha.stream includes everything you need. The app comes bundled with yt-dlp and ffmpeg, so you don't need to install anything else.

### How do I update fetcha.stream?

The app checks for updates automatically. When an update is available:
1. You'll see a notification
2. Click "Update Now"
3. The app will download and install the update
4. Restart to complete the update

You can also check manually: fetcha.stream → Check for Updates

### Can I use fetcha.stream commercially?

Yes, the MIT license allows commercial use. However, ensure you comply with the terms of service of the websites you're downloading from.

## Download Questions

### What sites does fetcha.stream support?

fetcha.stream supports over 1000 websites including:
- YouTube (including YouTube Music, Shorts)
- Vimeo
- Twitter/X
- Instagram
- TikTok
- Facebook
- Reddit
- Twitch
- Dailymotion
- SoundCloud
- And many more...

For a complete list, see [supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md).

### Can I download entire playlists?

Yes! Simply paste the playlist URL and fetcha.stream will:
1. Detect it's a playlist
2. Show you how many videos it contains
3. Let you choose to download all or select specific videos
4. Add them all to the download queue

### Can I download private or members-only videos?

Yes, if you have access to them. fetcha.stream can use your browser cookies to access:
- Private videos you have permission to view
- YouTube members-only content you're subscribed to
- Age-restricted videos (when logged in)
- Subscription-based content you pay for

Just select your browser in Preferences → Cookie Source.

### How do I download only audio?

Three ways to download audio:

1. **Quick method**: Select "Audio Only" from the format dropdown
2. **Preset method**: Use the "Audio Only" preset
3. **Custom method**: In Preferences, enable "Output Separate Audio"

Audio is saved as MP3 by default, but you can choose other formats (AAC, FLAC, WAV, etc.) in Preferences.

### Can I resume interrupted downloads?

Yes! fetcha.stream automatically resumes partial downloads when:
- You restart a failed download
- The app crashes and you restart it
- Your internet connection is restored

Set "File Overwrite Mode" to "Resume" in Preferences for best results.

### What's the maximum video length I can download?

There's no length limit imposed by fetcha.stream. You can download:
- Short clips (seconds)
- Regular videos (minutes to hours)
- Long streams (many hours)
- Live streams (while they're broadcasting)

The only limits are your available disk space and the source website's restrictions.

### Can I download live streams?

Yes, fetcha.stream can download:
- **Currently live streams**: Downloads in real-time as they broadcast
- **Scheduled streams**: Wait for them to start, then download
- **Past broadcasts**: If still available on the platform

Enable "Live from Start" in Preferences to download from the beginning of a live stream.

### Can I schedule downloads for later?

Yes, you can schedule downloads to start at a specific time:
1. Add videos to the queue
2. Right-click and select "Schedule"
3. Set the date and time
4. Keep fetcha.stream running (it can be minimized)

## Video Quality & Formats

### What video quality should I choose?

It depends on your needs:

| Quality | Best For | File Size | Notes |
|---------|----------|-----------|--------|
| **Best** | Archiving | Largest | Maximum available quality |
| **4K (2160p)** | 4K displays | Very large | Requires powerful hardware |
| **1080p** | HD viewing | Large | Standard for most uses |
| **720p** | General use | Medium | Good balance |
| **480p** | Mobile/saving space | Small | Acceptable quality |
| **Audio only** | Music/podcasts | Tiny | No video |

### What's the difference between MP4 and MKV?

**MP4**:
- Universal compatibility (plays everywhere)
- Smaller file size
- Limited subtitle/metadata support
- Best for sharing

**MKV**:
- Better quality preservation
- Multiple audio/subtitle tracks
- More metadata options
- Best for archiving

**WebM**:
- Open format
- Good compression
- Limited device support
- Best for web use

### Why are some videos downloaded in two parts?

High-quality videos often have separate video and audio streams:
1. Video stream (video only, no sound)
2. Audio stream (sound only, no video)

fetcha.stream automatically:
- Downloads both parts
- Merges them together
- Deletes the separate files (unless you choose to keep them)

### What does "best" quality mean?

"Best" automatically selects:
1. Highest resolution available
2. Best video codec (usually VP9 or H.264)
3. Highest bitrate audio
4. Optimal format combination

It's smart enough to balance quality with compatibility.

### Can I download HDR videos?

Yes, fetcha.stream preserves HDR (High Dynamic Range) when:
- The source video is HDR
- You select a format that supports HDR
- Your player/display supports HDR playback

HDR videos will be larger and may require specific players.

### What's the difference between H.264 and H.265?

**H.264 (AVC)**:
- Universal compatibility
- Larger file sizes
- Lower CPU requirements
- Works everywhere

**H.265 (HEVC)**:
- 50% smaller files at same quality
- Requires more CPU to play
- Not supported on all devices
- Better for storage-conscious users

### Why do some formats show as "video only" or "audio only"?

Modern streaming sites separate streams for efficiency:
- **Video only**: Different resolutions without duplicating audio
- **Audio only**: Different quality levels and languages
- **Combined**: Pre-merged, usually lower quality for compatibility

fetcha.stream handles this automatically, downloading and merging as needed.

## Browser & Cookies

### Which browsers are supported for cookie extraction?

fetcha.stream supports:
- **Safari** - macOS default browser
- **Chrome** - Including Chrome-based browsers
- **Firefox** - Including Firefox forks
- **Brave** - Privacy-focused Chrome alternative
- **Edge** - Microsoft's browser

### Why do I need browser cookies?

Cookies allow you to download:
- Private videos you have access to
- Age-restricted content
- Subscription/member content
- Videos requiring login
- Region-specific content (with your account)

Without cookies, you can only download publicly available videos.

### Is it safe to let fetcha.stream read my browser cookies?

Yes, it's safe:
- Cookies are read locally on your Mac
- Nothing is sent to external servers
- Only cookies for video sites are accessed
- Cookies are not stored by the app
- Process is similar to browser extensions

### How often do I need to refresh cookies?

Cookies typically last:
- **Session cookies**: Until you close the browser
- **Persistent cookies**: Days to months

Refresh cookies when:
- Downloads start failing for private videos
- You've logged out and back in
- You've changed your password
- It's been several weeks

### Can I use cookies from multiple browsers?

fetcha.stream uses one browser at a time, but you can switch between browsers in Preferences. This is useful if you have:
- Different accounts in different browsers
- Some sites working better with specific browsers
- Privacy separation between browsers

### What if my browser isn't detected?

If your browser doesn't appear:
1. Ensure it's installed in the Applications folder
2. Make sure it's a supported browser
3. Restart fetcha.stream
4. Try updating both the browser and fetcha.stream

As a workaround, you can export cookies to a file using a browser extension.

## File Management

### Where are videos saved?

By default, videos are saved to:
- **macOS default**: `~/Downloads/` (your Downloads folder)

You can change this in Preferences to:
- Any folder on your Mac
- External drives
- Network drives
- Different folders for different types

### Can I organize downloads into folders?

Yes! fetcha.stream offers several organization options:

1. **Separate folders by type**: Different locations for audio/video
2. **Subfolder templates**: Create folders based on channel/date
3. **Custom naming**: Include folder paths in naming template

Example template: `%(uploader)s/%(upload_date)s - %(title)s.%(ext)s`

Creates: `ChannelName/2024-01-15 - Video Title.mp4`

### How can I rename downloaded files?

Use naming templates in Preferences:

| Variable | Output | Example |
|----------|--------|---------|
| `%(title)s` | Video title | "Amazing Video" |
| `%(id)s` | Video ID | "dQw4w9WgXcQ" |
| `%(uploader)s` | Channel name | "ChannelName" |
| `%(upload_date)s` | Upload date | "20240115" |
| `%(resolution)s` | Video resolution | "1080p" |
| `%(ext)s` | File extension | "mp4" |

### What happens to incomplete downloads?

Incomplete downloads are saved with a `.part` extension. When you retry:
- fetcha.stream resumes from where it stopped
- No need to re-download the entire file
- Automatic cleanup after successful completion

### Can I move downloads after they're complete?

Yes! You can:
1. **Automatic moving**: Set up post-processing rules
2. **Manual moving**: Right-click → "Show in Finder"
3. **Different locations**: Configure separate folders for different types

### How much disk space do I need?

Required space depends on:
- **During download**: 2-3x the final file size (for temporary files)
- **Final file**: Varies by quality
  - 4K video: ~1-3 GB per 10 minutes
  - 1080p: ~200-500 MB per 10 minutes
  - 720p: ~100-200 MB per 10 minutes
  - Audio only: ~10-20 MB per 10 minutes

### Can I download directly to an external drive?

Yes! Just:
1. Connect your external drive
2. Open Preferences
3. Set Download Location to a folder on the external drive
4. Ensure the drive has enough space

## Performance & Speed

### Why are my downloads slow?

Common causes and solutions:

1. **Server throttling**: The website limits speeds
   - Try downloading at different times
   - Reduce concurrent downloads

2. **ISP throttling**: Your internet provider limits video sites
   - Try a VPN (if legal in your region)
   - Contact your ISP

3. **Rate limiting enabled**: Check Preferences → Network
   - Set Rate Limit to 0 for unlimited

4. **Too many concurrent downloads**: Overwhelming your connection
   - Reduce to 1-2 concurrent downloads

### How can I download faster?

Optimize for speed:
1. **Increase concurrent fragments**: Set to 5-10 in Preferences
2. **Use ethernet**: More stable than WiFi
3. **Close other apps**: Free up bandwidth
4. **Choose lower quality**: 720p downloads much faster than 4K
5. **Download during off-peak hours**: Less server congestion

### Can I limit download speed?

Yes, to avoid using all bandwidth:
1. Open Preferences → Network
2. Set "Rate Limit" in KB/s
3. Example: 500 KB/s leaves bandwidth for other activities

### How many videos can I download at once?

You can set 1-10 concurrent downloads in Preferences. Recommended:
- **Slow internet (< 10 Mbps)**: 1-2 concurrent
- **Medium internet (10-50 Mbps)**: 2-3 concurrent
- **Fast internet (> 50 Mbps)**: 3-5 concurrent
- **Very fast (> 100 Mbps)**: 5-10 concurrent

### Why does fetcha.stream use so much CPU?

CPU usage is normal during:
- **Merging**: Combining video and audio
- **Converting**: Changing formats
- **Multiple downloads**: Processing several streams

To reduce CPU usage:
- Download one video at a time
- Choose pre-merged formats
- Avoid format conversion
- Close unnecessary features

## Compatibility

### Which macOS versions are supported?

fetcha.stream requires:
- **Minimum**: macOS 11.0 (Big Sur)
- **Recommended**: macOS 12.0 (Monterey) or later
- **Tested on**: macOS 11, 12, 13, 14

Both Intel and Apple Silicon Macs are fully supported.

### Does fetcha.stream work on Apple Silicon Macs?

Yes! fetcha.stream is a Universal app that runs natively on:
- M1, M1 Pro, M1 Max, M1 Ultra
- M2, M2 Pro, M2 Max, M2 Ultra
- M3, M3 Pro, M3 Max
- Future Apple Silicon chips

No Rosetta required - full native performance.

### Can I use fetcha.stream on Windows or Linux?

fetcha.stream is macOS-only. For other platforms:
- **Windows/Linux**: Use yt-dlp directly (command line)
- **Cross-platform GUI**: Try youtube-dl-gui
- **Future**: We may develop versions for other platforms

### Will downloaded videos play on my device?

For maximum compatibility:
- **Format**: Choose MP4
- **Codec**: Select H.264
- **Resolution**: Match your device's screen
- **Audio**: Use AAC

These settings work on virtually all devices.

### Can I import my yt-dlp configuration?

Yes, fetcha.stream can read existing yt-dlp configurations:
1. Place your config at `~/.config/yt-dlp/config`
2. fetcha.stream will honor compatible settings
3. GUI settings take precedence over config file

### Does fetcha.stream work with VPNs?

Yes, fetcha.stream works normally with VPN connections. This can help with:
- Accessing geo-restricted content
- Bypassing ISP throttling
- Enhanced privacy

Ensure your VPN is connected before starting downloads.

## Privacy & Security

### Does fetcha.stream collect any data?

No, fetcha.stream:
- Collects zero user data
- Has no analytics or tracking
- Doesn't phone home
- Doesn't require an account
- Is completely private

### Is it legal to download videos?

The legality depends on:
- The specific video's copyright
- Your country's laws
- The website's terms of service
- Your intended use

Generally legal for:
- Content you created
- Public domain content
- Creative Commons licensed content
- Personal backup of purchased content

Always respect copyright and terms of service.

### How secure is the cookie feature?

Very secure:
- Cookies are read locally only
- No network transmission of cookies
- Temporary access only
- No storage of sensitive data
- Similar to browser's own security

### Does fetcha.stream modify my browser?

No, fetcha.stream:
- Only reads cookie data
- Doesn't modify browser settings
- Doesn't install extensions
- Doesn't change bookmarks
- Leaves your browser untouched

### Can fetcha.stream access my passwords?

No, fetcha.stream:
- Cannot read passwords
- Only accesses cookie data
- Cannot access keychain
- Cannot read saved logins
- Has no access to sensitive browser data

### Is the source code auditable?

Yes! fetcha.stream is fully open source:
- Complete source code on GitHub
- MIT licensed
- Publicly auditable
- Community reviewed
- Transparent development

## Troubleshooting

### What does "ERROR: Unable to extract video data" mean?

This usually means:
- The URL is invalid or incomplete
- The video is private/deleted
- The site changed its structure
- Network connection issues

Try:
1. Verify the URL works in a browser
2. Check if you need to be logged in
3. Update fetcha.stream
4. Enable cookies if needed

### Why does it say "No video formats found"?

Possible causes:
- Geographic restrictions
- Age restrictions
- Membership requirements
- Video processing on the site

Solutions:
- Use browser cookies
- Try a VPN
- Verify account access
- Wait and retry

### How do I report a bug?

To report a bug:
1. **Enable Debug Console**: Preferences → Advanced
2. **Reproduce the issue**: Try to trigger the bug
3. **Export logs**: Debug Console → Export
4. **Create issue**: GitHub Issues with:
   - Description of the problem
   - Steps to reproduce
   - Debug logs
   - System information

### Where can I get help?

Support resources:
- **Documentation**: Built-in help and online guides
- **FAQ**: This document
- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: Community help
- **Email Support**: support@fetcha.stream

### Why can't I download from [specific site]?

If a specific site doesn't work:
1. Check if it's in the [supported sites list](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md)
2. Try updating fetcha.stream
3. Test with yt-dlp directly
4. Report the issue with debug logs

## Advanced Features

### Can I use custom yt-dlp arguments?

Advanced users can add custom arguments:
1. Preferences → Advanced
2. "Custom Arguments" field
3. Add yt-dlp command-line options
4. These are appended to all downloads

### Does fetcha.stream support proxies?

Yes, configure proxy in Preferences → Network:
- HTTP proxies
- SOCKS proxies
- Authentication supported
- Per-download proxy possible

### Can I extract subtitles?

Yes! fetcha.stream can:
- Download available subtitles
- Auto-generate subtitles (if available)
- Embed in video file
- Save as separate files
- Convert between formats (SRT, VTT, ASS)

Configure in Preferences → Metadata & Subtitles.

### Can I process videos after download?

Post-processing options:
- Convert formats
- Extract audio
- Compress files
- Run custom scripts
- Add to media libraries

Set up in Preferences → Post-Processing.

### Is there an API or command-line interface?

Currently, fetcha.stream is GUI-only. For automation:
- Use yt-dlp directly for command-line
- Future versions may include API
- Export queue for batch processing
- Use AppleScript for basic automation

### Can I backup my settings?

Yes, your settings are stored in:
```
~/Library/Preferences/com.yourcompany.fetcha-stream.plist
```

To backup:
1. Export from Preferences → Export Settings
2. Or manually copy the plist file
3. Import on another Mac or after reinstall

### Can I create custom presets?

Yes! Create unlimited presets:
1. Configure your preferred settings
2. Preferences → Presets → Save Current
3. Name your preset
4. Choose an icon
5. Access via preset dropdown

Share presets by exporting/importing preset files.

---

Don't see your question? Check the [User Guide](USER_GUIDE.md) or [Troubleshooting Guide](TROUBLESHOOTING.md), or ask in [GitHub Discussions](https://github.com/yourusername/fetcha-stream/discussions).
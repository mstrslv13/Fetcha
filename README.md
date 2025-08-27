# Fetcha

A simple, yet powerful web media downloader for macOS. Built with Swift and SwiftUI, Fetcha provides a beautiful native interface for yt-dlp with browser cookie support and advanced features.

![macOS](https://img.shields.io/badge/macOS-11.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)
[https://giphy.com/stickers/buymeacoffee-creator-buy-me-a-coffee-support-7kZE0z52Sd9zSESzDA](https://buymeacoffee.com/mstrslva)



## What is Fetcha?

Fetcha is the easiest way to download videos on macOS. Whether you're saving tutorials for offline viewing, archiving content, or building a media library, Fetcha makes it simple. No command line knowledge required – just paste a URL and click download.

### Why Fetcha?

- **Dead Simple**: Copy a video URL and... done. It's that easy.
- **Browser Integration**: Automatically uses cookies from your browser to download private or age-restricted videos
- **Smart Downloads**: Automatically selects the best quality or lets you choose exactly what you want
- **Queue Management**: Download multiple videos without babysitting each one
- **Native macOS**: Built specifically for Mac with a beautiful, familiar interface

## Features

### 🎯 Core Functionality
- **One-Click Downloads** - Copy a URL and go!
- **Smart Format Selection** - Automatically picks the best quality or choose your own
- **Browser Cookie Support** - Download private videos using Safari, Chrome, Firefox, Brave, or Edge cookies
- **Download Queue** - Add multiple videos and let them download in sequence
- **Parallel Downloads** - Download multiple videos simultaneously (configurable)
- **Progress Tracking** - Real-time speed, progress bars, and time remaining

### 🎨 User Interface
- **Native macOS Design** - A true Mac app
- **Video Preview** - See thumbnails and metadata before downloading
- **Drag & Drop** - Reorder downloads in the queue with drag and drop
- **Keyboard Shortcuts** - Power user features for efficient workflow
- **Debug Console** - Built-in troubleshooting tools when you need them

### 📦 Advanced Features
- **Custom File Naming** - Use simple naming templates to organize your downloads
- **Bandwidth Management** - Set download speed limits
- **Auto-Retry** - Automatically retry failed downloads
- **Download History** - Keep track of what you've downloaded
- **Subtitle Support** - Download and embed subtitles
- **Metadata Embedding** - Include video information in the file

## System Requirements

- **macOS 11.0** (Big Sur) or later
- **Processor**: Intel or Apple Silicon (M1/M2/M3)
- **Memory**: 4GB RAM minimum, 8GB recommended
- **Storage**: 100MB for app + space for downloads
- **Network**: Internet connection for downloading videos

## Installation

### Method 1: Download Release (Recommended)

1. Download the latest `fetcha.dmg` from [Releases](https://github.com/mstrslv13/fetcha/releases)
2. Open the DMG file
3. Drag **fetcha.stream** to your **Applications** folder
4. **First Launch**: Right-click fetcha.stream and select "Open" (this bypasses Gatekeeper on first run)
5. Allow any security permissions when prompted

The app includes everything you need - no additional software required!

### Method 2: Homebrew (Coming Soon)

```bash
brew install --cask fetcha

### Method 3: Build from Source

Requires Xcode 13+ installed:

```bash
# Clone the repository
git clone https://github.com/mstrslv13/fetcha.git
cd fetcha-stream

# Open in Xcode
open yt-dlp-MAX.xcodeproj

# Build and run (or press ⌘+R in Xcode)
```

## Quick Start Guide

### Your First Download

1. **Find a Video**: Go to YouTube (or any supported site) and copy the video URL
4. **Automatically Downloads Upon Copying Valid Link**: The video will download with the best quality automatically

That's it! Your video will be saved to your Downloads folder by default.

### Choosing Video Quality

1. Paste your video URL
2. Right-click the queued item to open the context menu
3. Select your preferred quality from the dropdown

### Using Browser Cookies (For Private Videos)

1. Make sure you're logged into the video site in your browser
2. Open **Preferences** 
3. Select your browser from the **Cookie Source** dropdown
4. The app will automatically use your browser's cookies for downloads
5. For some browsers it is necessary to close the browser window

### Managing Multiple Downloads

1. Enable **Auto-add to queue** in Preferences for faster workflow
2. Paste multiple URLs - they'll be added to the queue automatically
3. Downloads will process in order (or simultaneously if configured)
4. Drag and drop to reorder items in the queue
5. Right-click items for options (pause, resume, remove)

## Configuration

### Essential Settings

Access Preferences by clicking the gear icon:

- **Download Location**: Where to save your videos
- **Default Quality**: Preferred video quality (best, 1080p, 720p, etc.)
- **Cookie Source**: Which browser to use for authentication
- **Auto-add to Queue**: Automatically queue URLs when pasted
- **Max Concurrent Downloads**: How many videos to download at once

### Advanced Settings

For power users who want more control:

- **Custom Naming Template**: Use variables like `%(title)s` for file names
- **Rate Limiting**: Control bandwidth usage
- **Subtitle Options**: Download and embed subtitles
- **Metadata Embedding**: Include video information in files

## Supported Sites

Fetcha supports **1000+ websites**, basically everything `yt-dlp` supports including:

- YouTube, YouTube Music, YouTube Shorts
- Vimeo, Dailymotion
- Twitter/X videos
- Instagram posts and reels
- TikTok videos
- Facebook videos
- Reddit videos
- Twitch streams and VODs
- SoundCloud, Bandcamp
- And many more!

For a complete list, visit [supported sites](https://github.com/yt-dlp/yt-dlp/blob/master/supportedsites.md).

## Troubleshooting

### Common Issues

**"Download Failed" Error**
- Check your internet connection
- Try updating the app to the latest version
- File already exists in location
- Enable debug console to see detailed error messages

**Can't Download Private Videos**
- Make sure you're logged into the site in your browser
- Select the correct browser in Preferences → Cookie Source
- Try logging out and back into the website

**Slow Download Speeds**
- Check if rate limiting is enabled in Preferences
- Try reducing concurrent downloads
- Your ISP or the video site may be throttling speeds

**Videos Won't Play After Download**
- Ensure the format is compatible with your media player
- Try selecting a different format (MP4 usually works everywhere)
- Check if the download completed successfully

For more solutions, see [Troubleshooting Guide](docs/TROUBLESHOOTING.md).

## Documentation

- [User Guide](docs/USER_GUIDE.md) - Detailed usage instructions
- [FAQ](docs/FAQ.md) - Frequently asked questions
- [Features](docs/FEATURES.md) - Complete feature documentation
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Solutions to common problems

## Development

### Building from Source

Requirements:
- macOS 11.0+
- Xcode 13+
- Swift 5.0+

```bash
# Debug build
xcodebuild -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX -configuration Debug

# Release build
xcodebuild -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX -configuration Release

# Run tests
xcodebuild test -project yt-dlp-MAX.xcodeproj -scheme yt-dlp-MAX
```

### Contributing

We welcome contributions! Please see:
- [Architecture Principles](docs/ARCHITECTURE_PRINCIPLES.md) - Understand the codebase
- [Contributing Guidelines](CONTRIBUTING.md) - How to contribute
- [Future Plans](docs/FUTURE_EVOLUTION.md) - Roadmap and vision

## Privacy & Security

- **No Data Collection**: Fetcha doesn't collect or transmit any user data
- **Local Processing**: All operations happen on your Mac
- **Cookie Security**: Browser cookies are only read when needed and never stored
- **Open Source**: Fully auditable source code

## Support

- **Tips**: [Buy me a coffee](https://buymeacoffee.com/mstrslva)
- **Issues**: [GitHub Issues](https://github.com/mstrslv13/Fetcha/issues)
- **Discussions**: [GitHub Discussions](https://github.com/mstrslv13/Fetcha/discussions)
- **Email**: dev@fetcha.stream

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful download engine
- [ffmpeg](https://ffmpeg.org/) - Media processing capabilities

---

Built with ❤️ for errbody

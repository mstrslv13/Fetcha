# Troubleshooting Guide

This guide helps you resolve common issues with fetcha.stream (yt-dlp-MAX). Each section includes symptoms, causes, and step-by-step solutions.

## Table of Contents

- [Installation Issues](#installation-issues)
- [Download Failures](#download-failures)
- [Cookie Problems](#cookie-problems)
- [Performance Issues](#performance-issues)
- [Format & Quality Issues](#format--quality-issues)
- [Queue Problems](#queue-problems)
- [File & Storage Issues](#file--storage-issues)
- [Network Errors](#network-errors)
- [Application Crashes](#application-crashes)
- [Getting Additional Help](#getting-additional-help)

## Quick Diagnostic Steps

Before diving into specific issues, try these general diagnostic steps:

1. **Check Internet Connection**: Ensure you have a stable connection
2. **Restart the App**: Quit and relaunch fetcha.stream
3. **Update the App**: Check for available updates
4. **Enable Debug Console**: View detailed error messages
5. **Test with YouTube**: Try downloading a public YouTube video as a baseline

## Installation Issues

### "fetcha.stream can't be opened because it is from an unidentified developer"

**Symptoms**: macOS blocks the app from opening

**Solution**:
1. Locate fetcha.stream in Applications folder
2. Right-click (or Control-click) the app
3. Select "Open" from the menu
4. Click "Open" in the dialog
5. The app will now be saved as an exception

**Alternative Method**:
1. Open System Preferences → Security & Privacy
2. Click the "General" tab
3. Click "Open Anyway" next to the fetcha.stream message
4. Enter your password if prompted

### "The application fetcha.stream can't be opened"

**Symptoms**: App won't launch at all

**Common Causes**:
- Incomplete download
- Corrupted app bundle
- Incompatible macOS version

**Solutions**:

1. **Re-download the app**:
   - Delete current app
   - Download fresh copy from official source
   - Move to Applications folder

2. **Check macOS version**:
   - Requires macOS 11.0 (Big Sur) or later
   - Update macOS if needed

3. **Reset permissions**:
   ```bash
   xattr -cr /Applications/fetcha.stream.app
   ```

### App crashes on launch

**Symptoms**: App opens briefly then closes

**Solutions**:

1. **Clear app preferences**:
   ```bash
   defaults delete com.yourcompany.fetcha-stream
   ```

2. **Check for conflicting software**:
   - Disable antivirus temporarily
   - Check for other download managers

3. **View crash logs**:
   - Open Console app
   - Search for "fetcha.stream"
   - Look for crash reports

## Download Failures

### "Failed to extract video information"

**Symptoms**: Can't fetch video metadata

**Common Causes**:
- Invalid or expired URL
- Private/deleted video
- Site changes or updates needed
- Network restrictions

**Solutions**:

1. **Verify the URL**:
   - Check if video plays in browser
   - Ensure URL is complete (not shortened)
   - Try copying URL again

2. **Check video availability**:
   - Is the video private or age-restricted?
   - Has the video been deleted?
   - Do you need to be logged in?

3. **Enable cookies** (for private videos):
   - Preferences → Cookie Source
   - Select your browser
   - Ensure you're logged into the site

4. **Try alternative URL format**:
   - Use direct video URL, not playlist URL
   - Remove timestamp parameters (?t=123)
   - Remove tracking parameters

### "Download speed is 0 KB/s" or download stalls

**Symptoms**: Download starts but makes no progress

**Common Causes**:
- Network interruption
- Server throttling
- Firewall/antivirus blocking
- Rate limiting

**Solutions**:

1. **Check network connection**:
   - Test with other downloads
   - Restart router/modem
   - Try different network

2. **Adjust concurrent settings**:
   - Preferences → Advanced
   - Reduce "Concurrent Fragments" to 1
   - Reduce "Max Concurrent Downloads" to 1

3. **Disable rate limiting**:
   - Preferences → Network
   - Set "Rate Limit" to 0 (unlimited)

4. **Check firewall/antivirus**:
   - Add fetcha.stream to exceptions
   - Temporarily disable to test
   - Check Little Snitch or similar tools

### "ERROR: Unable to download video data: HTTP Error 403: Forbidden"

**Symptoms**: Access denied errors

**Common Causes**:
- Geographic restrictions
- Account requirements
- Cookie issues
- IP blocking

**Solutions**:

1. **Use browser cookies**:
   - Log into the site in your browser
   - Select browser in Cookie Source
   - Try downloading again

2. **Check geographic restrictions**:
   - Enable "Geo Bypass" in Advanced settings
   - Consider using VPN (if legal in your region)

3. **Verify account access**:
   - Ensure subscription is active
   - Check if content requires purchase
   - Verify age verification

4. **Try different format**:
   - Some formats may be restricted
   - Use "Get Info" to see all options
   - Select different quality

### "Merging formats failed"

**Symptoms**: Video and audio won't combine

**Common Causes**:
- Corrupted partial download
- Insufficient disk space
- ffmpeg issues
- Incompatible formats

**Solutions**:

1. **Check disk space**:
   - Need 2-3x video size for merging
   - Clear space if needed
   - Change download location

2. **Re-download the video**:
   - Delete partial files
   - Clear from queue
   - Try downloading again

3. **Keep original files**:
   - Enable "Keep Original Files"
   - Manually merge with ffmpeg if needed

4. **Try different format**:
   - Select pre-merged format (usually 720p or lower)
   - Avoid separate video/audio streams

## Cookie Problems

### "No cookies found for this browser"

**Symptoms**: Can't detect browser cookies

**Solutions**:

1. **Verify browser is supported**:
   - Safari, Chrome, Firefox, Brave, Edge
   - Update browser to latest version

2. **Check browser profile**:
   - Ensure correct profile is active
   - Chrome/Firefox support multiple profiles

3. **Grant permissions**:
   - System Preferences → Security & Privacy
   - Allow fetcha.stream access
   - Restart the app

4. **Refresh cookies**:
   - Log out of website
   - Clear browser cookies
   - Log in again
   - Restart fetcha.stream

### "Cookie authentication failed"

**Symptoms**: Cookies detected but not working

**Common Causes**:
- Expired session
- Changed password
- Two-factor authentication
- Site updates

**Solutions**:

1. **Refresh browser session**:
   - Open website in browser
   - Ensure you can access content
   - Try download again

2. **Re-authenticate**:
   - Log out completely
   - Clear site cookies
   - Log in fresh
   - Enable "Remember me" if available

3. **Check 2FA status**:
   - Complete any 2FA challenges
   - Approve trusted device
   - Keep browser session active

### "Browser not detected"

**Symptoms**: Browser doesn't appear in dropdown

**Solutions**:

1. **Check browser installation**:
   - Ensure browser is in Applications folder
   - Not using portable version

2. **Restart fetcha.stream**:
   - Quit completely (⌘+Q)
   - Relaunch application

3. **Manual cookie file**:
   - Export cookies using browser extension
   - Save as cookies.txt
   - Select "Cookie File" in preferences

## Performance Issues

### Slow download speeds

**Symptoms**: Downloads much slower than internet speed

**Common Causes**:
- Server throttling
- Too many concurrent downloads
- Rate limiting enabled
- Network congestion

**Solutions**:

1. **Check rate limiting**:
   - Preferences → Network
   - Ensure "Rate Limit" is 0 or appropriate value

2. **Optimize concurrent settings**:
   - Reduce concurrent downloads to 1-2
   - Increase concurrent fragments to 5-10

3. **Test different times**:
   - Some sites throttle during peak hours
   - Try downloading at different times

4. **Check network usage**:
   - Close other bandwidth-heavy apps
   - Pause cloud sync services
   - Check for background updates

### High CPU usage

**Symptoms**: Mac gets hot, fans run loud

**Solutions**:

1. **Reduce concurrent operations**:
   - Lower max concurrent downloads
   - Reduce concurrent fragments
   - Process queue sequentially

2. **Disable unnecessary features**:
   - Turn off thumbnail embedding
   - Disable metadata processing
   - Skip subtitle downloads

3. **Check for stuck processes**:
   - Open Activity Monitor
   - Look for yt-dlp processes
   - Force quit if necessary

### Application feels sluggish

**Symptoms**: UI responds slowly

**Solutions**:

1. **Clear download history**:
   - Remove completed items from queue
   - Clear download history if very large

2. **Reduce queue size**:
   - Process large queues in batches
   - Remove completed items regularly

3. **Restart the app periodically**:
   - Memory usage can build up
   - Restart clears temporary data

## Format & Quality Issues

### "No suitable format found"

**Symptoms**: Can't find downloadable format

**Solutions**:

1. **Try different quality settings**:
   - Use "best" instead of specific resolution
   - Try lower quality options

2. **Update the app**:
   - Newer versions support more formats
   - Check for updates regularly

3. **Use format codes directly**:
   - Click "Get Info" to see all formats
   - Note format code (e.g., 137+140)
   - Enter manually in advanced options

### Downloaded video won't play

**Symptoms**: File downloads but won't open

**Common Causes**:
- Incompatible codec
- Corrupted download
- Player limitations

**Solutions**:

1. **Use compatible format**:
   - Download as MP4 with H.264
   - Avoid exotic codecs (AV1, VP9)
   - Use "compatibility mode" preset

2. **Try different player**:
   - VLC plays almost everything
   - IINA for modern codecs
   - QuickTime for maximum compatibility

3. **Convert the file**:
   - Use HandBrake for conversion
   - Or enable post-processing in settings

### Wrong quality downloaded

**Symptoms**: Gets different quality than selected

**Solutions**:

1. **Check availability**:
   - Not all qualities available for all videos
   - Older videos may lack HD options

2. **Verify settings**:
   - Check default quality in preferences
   - Ensure preset isn't overriding selection

3. **Use specific format codes**:
   - Get exact format with "Get Info"
   - Specify format code directly

## Queue Problems

### Queue items stuck in "Waiting" state

**Symptoms**: Downloads won't start

**Solutions**:

1. **Check concurrent download limit**:
   - May be waiting for others to finish
   - Increase limit in preferences

2. **Restart queue processing**:
   - Pause all downloads
   - Resume queue

3. **Clear and re-add**:
   - Remove stuck items
   - Re-add to queue

### Can't remove items from queue

**Symptoms**: Delete key doesn't work

**Solutions**:

1. **Stop download first**:
   - Pause or cancel active download
   - Then remove from queue

2. **Use context menu**:
   - Right-click item
   - Select "Remove from Queue"

3. **Force quit process**:
   - If completely stuck
   - Restart app
   - Queue should be clearable

### Queue order keeps changing

**Symptoms**: Items don't stay in set order

**Solutions**:

1. **Disable auto-sort**:
   - Check queue settings
   - Turn off any automatic sorting

2. **Wait for current downloads**:
   - Order changes during active downloads
   - Set order when queue is paused

## File & Storage Issues

### "Not enough disk space" error

**Symptoms**: Download fails with space error

**Solutions**:

1. **Check available space**:
   - Need 2-3x final file size
   - Account for temporary files during merge

2. **Change download location**:
   - Use external drive
   - Select different folder with more space

3. **Clean up old downloads**:
   - Delete completed downloads
   - Clear temporary files
   - Empty trash

### Files disappear after download

**Symptoms**: Can't find downloaded files

**Common Causes**:
- Wrong download location
- Hidden by naming template
- Cleaned up after merge

**Solutions**:

1. **Check download location**:
   - Preferences → General
   - Note the download path
   - Check all configured locations

2. **Search by filename**:
   - Use Spotlight search
   - Search for video title
   - Check for variant names

3. **Enable "Keep Original Files"**:
   - Prevents deletion after merge
   - Find intermediate files

### Duplicate downloads

**Symptoms**: Same video downloaded multiple times

**Solutions**:

1. **Enable skip existing**:
   - Set "File Overwrite Mode" to "Skip"
   - Avoids re-downloading

2. **Use download archive**:
   - Advanced settings
   - Tracks downloaded video IDs
   - Prevents re-downloading even if moved

## Network Errors

### "Connection timeout" errors

**Symptoms**: Downloads fail to start

**Solutions**:

1. **Increase timeout values**:
   - Preferences → Network
   - Increase "Socket Timeout"
   - Try 60-120 seconds

2. **Check firewall settings**:
   - Allow fetcha.stream through firewall
   - Check router settings
   - Disable VPN temporarily

3. **Try different DNS**:
   - Change to 8.8.8.8 or 1.1.1.1
   - Flush DNS cache
   - Restart network

### "SSL certificate verify failed"

**Symptoms**: HTTPS connection errors

**Solutions**:

1. **Check system date/time**:
   - Ensure clock is correct
   - Enable automatic time

2. **Update certificates**:
   - Update macOS
   - Update fetcha.stream

3. **Bypass verification** (temporary):
   - Only for testing
   - Advanced settings
   - Re-enable after testing

## Application Crashes

### App crashes during download

**Symptoms**: App quits unexpectedly

**Solutions**:

1. **Check crash reports**:
   ```bash
   ~/Library/Logs/DiagnosticReports/
   ```
   - Look for fetcha.stream crashes
   - Note error details

2. **Reset app state**:
   - Clear preferences
   - Remove queue database
   - Start fresh

3. **Reduce load**:
   - Lower concurrent downloads
   - Smaller queue size
   - Simpler operations

### Won't open after crash

**Symptoms**: App won't launch

**Solutions**:

1. **Delete preference files**:
   ```bash
   ~/Library/Preferences/com.yourcompany.fetcha-stream.plist
   ```

2. **Clear cache**:
   ```bash
   ~/Library/Caches/com.yourcompany.fetcha-stream/
   ```

3. **Reinstall app**:
   - Complete uninstall
   - Fresh download
   - Clean install

## Getting Additional Help

### Debug Information

When reporting issues, include:

1. **Enable Debug Console**:
   - Preferences → Advanced → Show Debug Console
   - Copy relevant error messages

2. **System Information**:
   - macOS version
   - fetcha.stream version
   - Mac model (Intel/Apple Silicon)

3. **Steps to Reproduce**:
   - Exact URL (if public)
   - Settings used
   - When error occurs

4. **Error Messages**:
   - Complete error text
   - Screenshots if helpful

### Export Debug Logs

1. Open Debug Console
2. Try to reproduce the issue
3. Click "Export Logs"
4. Include with bug report

### Contact Support

**Before contacting support**:
- Try solutions in this guide
- Search existing issues on GitHub
- Prepare debug information

**Support Channels**:
- **GitHub Issues**: [Bug reports](https://github.com/yourusername/fetcha-stream/issues)
- **Discussions**: [Community help](https://github.com/yourusername/fetcha-stream/discussions)
- **Email**: support@fetcha.stream
- **Twitter**: @fetchastream

### Common Error Codes

| Code | Meaning | Solution |
|------|---------|----------|
| 403 | Forbidden | Use cookies, check region |
| 404 | Not Found | Check URL, video may be deleted |
| 410 | Gone | Video removed |
| 429 | Too Many Requests | Wait and retry, reduce concurrent downloads |
| 500 | Server Error | Wait and retry later |
| 1001 | Network Error | Check connection |
| 2001 | Format Error | Try different quality |
| 3001 | Merge Error | Check disk space |

### Advanced Debugging

For persistent issues:

1. **Run from Terminal**:
   ```bash
   /Applications/fetcha.stream.app/Contents/MacOS/fetcha.stream --debug
   ```

2. **Check system logs**:
   ```bash
   log show --predicate 'process == "fetcha.stream"' --last 1h
   ```

3. **Test with yt-dlp directly**:
   ```bash
   yt-dlp --verbose [URL]
   ```

Remember: Most issues have simple solutions. Start with basic steps before trying advanced fixes. If you discover a new issue or solution, please share it with the community!
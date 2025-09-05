import Foundation
import SwiftUI

class RSSFeedParser: NSObject {
    
    struct RSSItem {
        let title: String
        let link: String?
        let videoURL: String?
        let description: String?
        let pubDate: Date?
        let thumbnail: String?
        let duration: String?
        
        var hasVideo: Bool {
            return videoURL != nil || (link?.contains("youtube.com") ?? false) || 
                   (link?.contains("youtu.be") ?? false) || 
                   (link?.contains("vimeo.com") ?? false)
        }
    }
    
    struct RSSFeed {
        let title: String
        let description: String?
        let items: [RSSItem]
        
        var videoItems: [RSSItem] {
            items.filter { $0.hasVideo }
        }
    }
    
    enum ParseError: LocalizedError {
        case invalidURL
        case invalidData
        case parsingFailed(String)
        case noVideosFound
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid RSS feed URL"
            case .invalidData:
                return "Unable to load RSS feed data"
            case .parsingFailed(let message):
                return "Failed to parse RSS feed: \(message)"
            case .noVideosFound:
                return "No video URLs found in RSS feed"
            }
        }
    }
    
    // Parse RSS feed from URL
    static func parseFeed(from urlString: String) async throws -> RSSFeed {
        guard let url = URL(string: urlString) else {
            throw ParseError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try parseFeed(from: data)
    }
    
    // Parse RSS feed from data
    static func parseFeed(from data: Data) throws -> RSSFeed {
        let parser = RSSXMLParser()
        return try parser.parse(data: data)
    }
}

// XML Parser implementation
private class RSSXMLParser: NSObject, XMLParserDelegate {
    private var feed: RSSFeedParser.RSSFeed?
    private var items: [RSSFeedParser.RSSItem] = []
    private var currentItem: RSSFeedParser.RSSItem?
    
    // Feed properties
    private var feedTitle = ""
    private var feedDescription: String?
    
    // Current item properties
    private var itemTitle = ""
    private var itemLink: String?
    private var itemVideoURL: String?
    private var itemDescription: String?
    private var itemPubDate: Date?
    private var itemThumbnail: String?
    private var itemDuration: String?
    
    // Parsing state
    private var currentElement = ""
    private var currentValue = ""
    private var isInItem = false
    private var parseError: Error?
    
    func parse(data: Data) throws -> RSSFeedParser.RSSFeed {
        let parser = XMLParser(data: data)
        parser.delegate = self
        
        if parser.parse() {
            if let error = parseError {
                throw error
            }
            
            let feed = RSSFeedParser.RSSFeed(
                title: feedTitle,
                description: feedDescription,
                items: items
            )
            
            if feed.videoItems.isEmpty && !items.isEmpty {
                throw RSSFeedParser.ParseError.noVideosFound
            }
            
            return feed
        } else {
            if let error = parser.parserError {
                throw RSSFeedParser.ParseError.parsingFailed(error.localizedDescription)
            }
            throw RSSFeedParser.ParseError.parsingFailed("Unknown parsing error")
        }
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, 
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String : String] = [:]) {
        
        currentElement = elementName.lowercased()
        currentValue = ""
        
        switch currentElement {
        case "item", "entry":
            isInItem = true
            // Reset item properties
            itemTitle = ""
            itemLink = nil
            itemVideoURL = nil
            itemDescription = nil
            itemPubDate = nil
            itemThumbnail = nil
            itemDuration = nil
            
        case "enclosure":
            // Standard RSS enclosure for media
            if let type = attributeDict["type"], 
               type.contains("video") || type.contains("audio") {
                itemVideoURL = attributeDict["url"]
            } else if let url = attributeDict["url"] {
                // Check if URL looks like a video
                if isVideoURL(url) {
                    itemVideoURL = url
                }
            }
            
        case "media:content":
            // Media RSS extension
            if let url = attributeDict["url"] {
                if let type = attributeDict["type"],
                   (type.contains("video") || type.contains("audio")) {
                    itemVideoURL = url
                } else if isVideoURL(url) {
                    itemVideoURL = url
                }
            }
            if let duration = attributeDict["duration"] {
                itemDuration = duration
            }
            
        case "media:thumbnail", "itunes:image":
            itemThumbnail = attributeDict["url"] ?? attributeDict["href"]
            
        case "youtube:videoId":
            // YouTube-specific RSS
            // We'll construct the URL when we get the value
            break
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        
        let element = elementName.lowercased()
        let value = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !isInItem {
            // Feed-level elements
            switch element {
            case "title":
                if feedTitle.isEmpty {
                    feedTitle = value
                }
            case "description", "subtitle":
                if feedDescription == nil {
                    feedDescription = value
                }
            default:
                break
            }
        } else {
            // Item-level elements
            switch element {
            case "title":
                itemTitle = value
                
            case "link", "guid":
                if itemLink == nil && !value.isEmpty {
                    itemLink = value
                    // Check if this is a video URL
                    if isVideoURL(value) {
                        itemVideoURL = value
                    }
                }
                
            case "description", "summary", "content:encoded":
                if itemDescription == nil {
                    itemDescription = value
                    // Try to extract video URLs from description
                    if itemVideoURL == nil {
                        itemVideoURL = extractVideoURL(from: value)
                    }
                }
                
            case "pubdate", "published", "updated":
                itemPubDate = parseDate(value)
                
            case "youtube:videoId":
                // Construct YouTube URL from video ID
                if !value.isEmpty {
                    itemVideoURL = "https://www.youtube.com/watch?v=\(value)"
                }
                
            case "media:description":
                if itemDescription == nil {
                    itemDescription = value
                }
                
            case "itunes:duration", "duration":
                itemDuration = value
                
            case "item", "entry":
                // End of item
                isInItem = false
                
                let item = RSSFeedParser.RSSItem(
                    title: itemTitle,
                    link: itemLink,
                    videoURL: itemVideoURL,
                    description: itemDescription,
                    pubDate: itemPubDate,
                    thumbnail: itemThumbnail,
                    duration: itemDuration
                )
                
                items.append(item)
                
            default:
                break
            }
        }
        
        currentValue = ""
    }
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = parseError
    }
    
    // MARK: - Helper Methods
    
    private func isVideoURL(_ url: String) -> Bool {
        let videoPatterns = [
            "youtube.com/watch",
            "youtu.be/",
            "vimeo.com/",
            "dailymotion.com/",
            "twitter.com/.*/status/",
            "x.com/.*/status/",
            "instagram.com/p/",
            "tiktok.com/",
            ".mp4", ".m4v", ".mov", ".avi", ".mkv", ".webm"
        ]
        
        let lowercased = url.lowercased()
        return videoPatterns.contains { lowercased.contains($0) }
    }
    
    private func extractVideoURL(from text: String) -> String? {
        // Try to find video URLs in text (e.g., in description)
        let patterns = [
            "(https?://[\\w\\.-]+youtube\\.com/watch\\?v=[\\w-]+)",
            "(https?://youtu\\.be/[\\w-]+)",
            "(https?://[\\w\\.-]+vimeo\\.com/[\\d]+)",
            "(https?://[\\w\\.-]+dailymotion\\.com/video/[\\w]+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                return String(text[range])
            }
        }
        
        return nil
    }
    
    private func parseDate(_ dateString: String) -> Date? {
        let formatters = [
            DateFormatter.rfc822,
            DateFormatter.iso8601Full,
            DateFormatter.iso8601,
            DateFormatter.rfc3339
        ]
        
        for formatter in formatters {
            if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: dateString) {
                    return date
                }
            } else if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                if let date = iso8601Formatter.date(from: dateString) {
                    return date
                }
            }
        }
        
        return nil
    }
}

// Date formatter extensions
private extension DateFormatter {
    static let rfc822: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    static let rfc3339: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

// RSS Import Preview View
struct RSSImportPreviewView: View {
    let feed: RSSFeedParser.RSSFeed
    let onImport: ([String]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedItems = Set<String>()
    @State private var selectAll = true
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Text(feed.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                }
                
                if let description = feed.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Label("\(feed.videoItems.count) videos found", systemImage: "play.rectangle.fill")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Spacer()
                    
                    Toggle("Select All", isOn: $selectAll)
                        .toggleStyle(.checkbox)
                        .onChange(of: selectAll) { oldValue, newValue in
                            if newValue {
                                selectedItems = Set(feed.videoItems.compactMap { $0.videoURL ?? $0.link })
                            } else {
                                selectedItems.removeAll()
                            }
                        }
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            
            Divider()
            
            // Video list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(feed.videoItems, id: \.title) { item in
                        RSSItemRow(
                            item: item,
                            isSelected: selectedItems.contains(item.videoURL ?? item.link ?? ""),
                            onToggle: { selected in
                                let url = item.videoURL ?? item.link ?? ""
                                if selected {
                                    selectedItems.insert(url)
                                } else {
                                    selectedItems.remove(url)
                                }
                                selectAll = selectedItems.count == feed.videoItems.count
                            }
                        )
                    }
                }
                .padding()
            }
            .frame(maxHeight: 400)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(8)
            
            Divider()
            
            // Buttons
            HStack {
                Text("\(selectedItems.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape)
                
                Button("Import Selected") {
                    onImport(Array(selectedItems))
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedItems.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 600)
        .onAppear {
            // Select all by default
            selectedItems = Set(feed.videoItems.compactMap { $0.videoURL ?? $0.link })
        }
    }
}

struct RSSItemRow: View {
    let item: RSSFeedParser.RSSItem
    let isSelected: Bool
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Toggle("", isOn: .init(
                get: { isSelected },
                set: { onToggle($0) }
            ))
            .toggleStyle(.checkbox)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                
                if let url = item.videoURL ?? item.link {
                    Text(url)
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                }
                
                if let date = item.pubDate {
                    Text(date, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if let duration = item.duration {
                Text(duration)
                    .font(.caption.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
        .padding(8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}
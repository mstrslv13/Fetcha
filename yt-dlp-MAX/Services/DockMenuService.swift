import AppKit
import SwiftUI

class DockMenuService: NSObject {
    static let shared = DockMenuService()
    
    private var dockMenu: NSMenu?
    private var downloadHistory: DownloadHistory
    
    override init() {
        self.downloadHistory = DownloadHistory.shared
        super.init()
        setupDockMenu()
    }
    
    private func setupDockMenu() {
        dockMenu = NSMenu()
        updateDockMenu()
    }
    
    func getDockMenu() -> NSMenu? {
        updateDockMenu()
        return dockMenu
    }
    
    func updateDockMenu() {
        guard let menu = dockMenu else { return }
        
        // Clear existing items
        menu.removeAllItems()
        
        // Add header
        let headerItem = NSMenuItem(title: "Recent Downloads", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())
        
        // Get last 30 downloads that still exist
        let recentDownloads = Array(downloadHistory.history)
            .filter { downloadHistory.verifyDownloadExists($0) }
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(30)
        
        if recentDownloads.isEmpty {
            let emptyItem = NSMenuItem(title: "No recent downloads", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            // Group by date
            let calendar = Calendar.current
            let grouped = Dictionary(grouping: recentDownloads) { download in
                calendar.startOfDay(for: download.timestamp)
            }
            
            let sortedDates = grouped.keys.sorted(by: >)
            
            for (index, date) in sortedDates.enumerated() {
                if index > 0 {
                    menu.addItem(NSMenuItem.separator())
                }
                
                // Add date header
                let formatter = DateFormatter()
                formatter.doesRelativeDateFormatting = true
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                
                let dateHeader = NSMenuItem(title: formatter.string(from: date), action: nil, keyEquivalent: "")
                dateHeader.isEnabled = false
                dateHeader.attributedTitle = NSAttributedString(
                    string: formatter.string(from: date),
                    attributes: [
                        .font: NSFont.boldSystemFont(ofSize: 11),
                        .foregroundColor: NSColor.secondaryLabelColor
                    ]
                )
                menu.addItem(dateHeader)
                
                // Add downloads for this date
                if let downloads = grouped[date] {
                    for download in downloads.sorted(by: { $0.timestamp > $1.timestamp }) {
                        let menuItem = createMenuItem(for: download)
                        menu.addItem(menuItem)
                    }
                }
            }
        }
        
        // Add separator and utility items
        menu.addItem(NSMenuItem.separator())
        
        // Open downloads folder
        let openFolderItem = NSMenuItem(
            title: "Open Downloads Folder",
            action: #selector(openDownloadsFolder),
            keyEquivalent: ""
        )
        openFolderItem.target = self
        menu.addItem(openFolderItem)
        
        // Clear history
        if !recentDownloads.isEmpty {
            let clearItem = NSMenuItem(
                title: "Clear History",
                action: #selector(clearHistory),
                keyEquivalent: ""
            )
            clearItem.target = self
            menu.addItem(clearItem)
        }
    }
    
    private func createMenuItem(for download: DownloadHistory.DownloadRecord) -> NSMenuItem {
        // Create menu item with title
        let title = String(download.title.prefix(50))
        let menuItem = NSMenuItem(
            title: title,
            action: #selector(openFile(_:)),
            keyEquivalent: ""
        )
        
        // Store file path in represented object
        menuItem.representedObject = download.downloadPath
        menuItem.target = self
        
        // Add subtitle with time and size
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let timeString = formatter.string(from: download.timestamp)
        
        var subtitle = timeString
        if let duration = download.duration {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            subtitle += " • \(String(format: "%d:%02d", minutes, seconds))"
        }
        if let fileSize = download.fileSize {
            let sizeFormatter = ByteCountFormatter()
            sizeFormatter.countStyle = .file
            subtitle += " • \(sizeFormatter.string(fromByteCount: fileSize))"
        }
        
        // Create attributed string for title and subtitle
        let attributedTitle = NSMutableAttributedString()
        attributedTitle.append(NSAttributedString(
            string: title,
            attributes: [.font: NSFont.menuFont(ofSize: 13)]
        ))
        attributedTitle.append(NSAttributedString(
            string: "\n\(subtitle)",
            attributes: [
                .font: NSFont.menuFont(ofSize: 10),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))
        
        menuItem.attributedTitle = attributedTitle
        
        // Add icon
        if let image = NSImage(systemSymbolName: "play.circle", accessibilityDescription: nil) {
            image.size = NSSize(width: 16, height: 16)
            menuItem.image = image
        }
        
        // Add alternate action for showing in Finder
        menuItem.isAlternate = false
        menuItem.keyEquivalentModifierMask = []
        
        return menuItem
    }
    
    @objc private func openFile(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        let url = URL(fileURLWithPath: path)
        
        // Verify file exists before opening
        if FileManager.default.fileExists(atPath: path) {
            // Open the actual file
            NSWorkspace.shared.open(url)
        } else {
            // File doesn't exist, show parent folder
            let parentURL = url.deletingLastPathComponent()
            NSWorkspace.shared.open(parentURL)
        }
    }
    
    @objc private func openDownloadsFolder() {
        let downloadPath = AppPreferences.shared.resolvedDownloadPath
        let url = URL(fileURLWithPath: downloadPath)
        NSWorkspace.shared.open(url)
    }
    
    @objc private func clearHistory() {
        downloadHistory.clearHistory()
        updateDockMenu()
    }
    
    // Call this when a download completes to update the dock menu
    func notifyDownloadCompleted() {
        DispatchQueue.main.async {
            self.updateDockMenu()
        }
    }
}
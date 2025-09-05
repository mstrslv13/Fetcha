//
//  yt_dlp_MAXApp.swift
//  yt-dlp-MAX
//
//  Created by mstrslv on 8/22/25.
//

import SwiftUI
import AppKit

// App Delegate for dock menu support
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return DockMenuService.shared.getDockMenu()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize dock menu service
        _ = DockMenuService.shared
    }
}

@main
struct yt_dlp_MAXApp: App {
    @StateObject private var processManager = ProcessManager.shared
    @StateObject private var preferences = AppPreferences.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    init() {
        // Ensure ProcessManager is initialized
        _ = ProcessManager.shared
        
        // Set the app icon (dock icon)
        if let appIcon = NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = appIcon
        }
    }
    
    var body: some Scene {
        WindowGroup(preferences.privateMode ? "Fetcha (Private)" : "Fetcha") {
            ContentView()
                .onDisappear {
                    // Clean up when window closes
                    Task {
                        await ProcessManager.shared.terminateAll()
                    }
                }
                .onAppear {
                    // Disable fullscreen mode for all windows
                    if let window = NSApplication.shared.windows.first {
                        window.collectionBehavior.remove(.fullScreenPrimary)
                        window.styleMask.remove(.fullScreen)
                        // Remove the fullscreen button
                        if let button = window.standardWindowButton(.zoomButton) {
                            button.isEnabled = false
                        }
                    }
                }
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Fetcha") {
                    NSApplication.showAboutWindow()
                }
                .keyboardShortcut("A", modifiers: [.command, .shift])
            }
        }
    }
}

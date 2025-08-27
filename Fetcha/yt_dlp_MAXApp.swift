//
//  yt_dlp_MAXApp.swift
//  yt-dlp-MAX
//
//  Created by mstrslv on 8/22/25.
//

import SwiftUI
import AppKit

@main
struct yt_dlp_MAXApp: App {
    @StateObject private var processManager = ProcessManager.shared
    
    init() {
        // Ensure ProcessManager is initialized
        _ = ProcessManager.shared
    }
    
    var body: some Scene {
        WindowGroup("Fetcha") {
            ContentView()
                .onDisappear {
                    // Clean up when window closes
                    Task {
                        await ProcessManager.shared.terminateAll()
                    }
                }
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Fetcha") {
                    showAboutWindow()
                }
            }
        }
    }
    
    private func showAboutWindow() {
        let aboutView = AboutView()
        let hostingController = NSHostingController(rootView: aboutView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About Fetcha"
        window.styleMask = [.titled, .closable]
        window.isMovableByWindowBackground = true
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}

import SwiftUI
import AppKit

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            // App icon and name
            VStack(spacing: 10) {
                Image(nsImage: NSImage(named: "AppIcon") ?? NSImage())
                    .resizable()
                    .frame(width: 64, height: 64)
                
                Text("Fetcha")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tagline
            Text("A simple, yet powerful web media downloader for macOS")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
            
            // Dedication
            VStack(spacing: 8) {
                Text("In loving memory of")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Zephy")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("2012 - 2022")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 5)
            
            Divider()
            
            // Copyright and Contact
            VStack(spacing: 8) {
                Text("Copyright © 2025 William Azada")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Contact:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button("dev@fetcha.stream") {
                        if let url = URL(string: "mailto:dev@fetcha.stream") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }
            }
            
            Divider()
            
            // Links
            HStack(spacing: 20) {
                Button("View on GitHub") {
                    if let url = URL(string: "https://github.com/mstrslv/yt-dlp-MAX") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
                
                Button("Report Issue") {
                    if let url = URL(string: "https://github.com/mstrslv/yt-dlp-MAX/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
            }
        }
        .padding(40)
        .frame(width: 450)
    }
}
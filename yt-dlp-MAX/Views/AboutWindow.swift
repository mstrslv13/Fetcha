import SwiftUI

struct AboutWindow: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer(minLength: 10)
            
            // App Icon - Dog logo
            Image("DogLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
            
            Text("Fetcha")
                .font(.system(size: 36))
                .fontWeight(.bold)
            
            Text("Version 0.9.0")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Text("A simple, powerful streaming media fetcher for macOS")
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 6) {
                Text("In loving memory of")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("Zephy")
                    .font(.system(size: 16, weight: .semibold))
                
                Text("2012 - 2022")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
            
            Divider()
                .frame(width: 200)
            
            VStack(spacing: 8) {
                Text("Copyright © 2025 William Azada")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                Text("Contact: dev@fetcha.stream")
                    .font(.system(size: 12))
                    .foregroundColor(.accentColor)
            }
            
            Spacer(minLength: 10)
            
            // Coffee button
            Link(destination: URL(string: "https://buymeacoffee.com/mstrslva")!) {
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                    Text("Buy me a coffee")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .buttonStyle(PlainButtonStyle())
            
            HStack(spacing: 20) {
                Link("View on GitHub", destination: URL(string: "https://github.com/mstrslv13/fetcha")!)
                    .font(.system(size: 12))
                
                Link("Report Issue", destination: URL(string: "https://github.com/mstrslv13/fetcha/issues")!)
                    .font(.system(size: 12))
            }
            
            Spacer(minLength: 10)
        }
        .frame(width: 420, height: 480)
        .padding(25)
    }
}

// Helper to open About window
extension NSApplication {
    static func showAboutWindow() {
        let aboutView = AboutWindow()
        let hostingController = NSHostingController(rootView: aboutView)
        let window = NSWindow(contentViewController: hostingController)
        window.title = "About Fetcha"
        window.styleMask = [.titled, .closable]
        window.center()
        window.makeKeyAndOrderFront(nil)
    }
}
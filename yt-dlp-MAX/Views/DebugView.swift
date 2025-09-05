import SwiftUI
import AppKit
import UniformTypeIdentifiers

class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    @Published var logs: [DebugLog] = []
    private let maxLogs = 500
    
    struct DebugLog: Identifiable {
        let id = UUID()
        let timestamp: Date
        let level: LogLevel
        let message: String
        let details: String?
        
        enum LogLevel {
            case info, warning, error, success, command
            
            var color: Color {
                switch self {
                case .info: return .primary
                case .warning: return Color.orange
                case .error: return Color.red
                case .success: return Color.green
                case .command: return Color.purple
                }
            }
            
            var icon: String {
                switch self {
                case .info: return "info.circle"
                case .warning: return "exclamationmark.triangle"
                case .error: return "xmark.circle"
                case .success: return "checkmark.circle"
                case .command: return "terminal"
                }
            }
        }
    }
    
    func log(_ message: String, level: DebugLog.LogLevel = .info, details: String? = nil) {
        DispatchQueue.main.async {
            let log = DebugLog(timestamp: Date(), level: level, message: message, details: details)
            self.logs.insert(log, at: 0)
            
            // Keep only the most recent logs
            if self.logs.count > self.maxLogs {
                self.logs = Array(self.logs.prefix(self.maxLogs))
            }
            
            // Also print to console for Xcode debugging
            let levelPrefix = switch level {
            case .info: "ℹ️"
            case .warning: "⚠️"
            case .error: "❌"
            case .success: "✅"
            case .command: "🖥️"
            }
            print("\(levelPrefix) \(message)")
            if let details = details {
                print("   └─ \(details)")
            }
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
        }
    }
}

struct DebugView: View {
    @StateObject private var logger = DebugLogger.shared
    @State private var filterLevel: DebugLogger.DebugLog.LogLevel?
    @State private var searchText = ""
    @State private var autoScroll = true
    
    var filteredLogs: [DebugLogger.DebugLog] {
        logger.logs.filter { log in
            let matchesLevel = filterLevel == nil || log.level == filterLevel
            let matchesSearch = searchText.isEmpty || 
                log.message.localizedCaseInsensitiveContains(searchText) ||
                (log.details?.localizedCaseInsensitiveContains(searchText) ?? false)
            return matchesLevel && matchesSearch
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Debug Console")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // Filter buttons
                HStack(spacing: 8) {
                    FilterButton(title: "All", level: nil, currentFilter: $filterLevel)
                    FilterButton(title: "Info", level: .info, currentFilter: $filterLevel)
                    FilterButton(title: "Warning", level: .warning, currentFilter: $filterLevel)
                    FilterButton(title: "Error", level: .error, currentFilter: $filterLevel)
                    FilterButton(title: "Success", level: .success, currentFilter: $filterLevel)
                    FilterButton(title: "Command", level: .command, currentFilter: $filterLevel)
                }
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 8)
                
                Toggle("Auto-scroll", isOn: $autoScroll)
                    .toggleStyle(.checkbox)
                
                Button(action: exportLogs) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .help("Export logs to file")
                
                Button("Clear") {
                    logger.clear()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            // Logs
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        if filteredLogs.isEmpty {
                            Text("No logs to display")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(filteredLogs) { log in
                                LogRowView(log: log)
                                    .id(log.id)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(NSColor.textBackgroundColor))
                .onChange(of: logger.logs.count) { oldValue, newValue in
                    if autoScroll && !filteredLogs.isEmpty {
                        withAnimation {
                            proxy.scrollTo(filteredLogs.first?.id, anchor: .top)
                        }
                    }
                }
            }
        }
        .frame(width: 800, height: 600)
    }
    
    private func exportLogs() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Debug Logs"
        savePanel.message = "Choose where to save the debug logs"
        savePanel.prompt = "Export"
        savePanel.nameFieldStringValue = "fetcha_debug_\(Date().timeIntervalSince1970).txt"
        savePanel.allowedContentTypes = [.plainText]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                var logContent = "Fetcha Debug Logs - Exported \(Date())\n"
                logContent += "========================================\n\n"
                
                for log in filteredLogs {
                    let timestamp = DateFormatter.localizedString(from: log.timestamp, dateStyle: .short, timeStyle: .medium)
                    logContent += "[\(timestamp)] [\(log.level)] \(log.message)\n"
                    if let details = log.details {
                        logContent += "  Details: \(details)\n"
                    }
                    logContent += "\n"
                }
                
                do {
                    try logContent.write(to: url, atomically: true, encoding: .utf8)
                    DebugLogger.shared.log("Logs exported successfully", level: .success, details: url.path)
                } catch {
                    DebugLogger.shared.log("Failed to export logs", level: .error, details: error.localizedDescription)
                }
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let level: DebugLogger.DebugLog.LogLevel?
    @Binding var currentFilter: DebugLogger.DebugLog.LogLevel?
    
    var isSelected: Bool {
        if level == nil && currentFilter == nil { return true }
        return level == currentFilter
    }
    
    var body: some View {
        Button(action: { currentFilter = level }) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct LogRowView: View {
    let log: DebugLogger.DebugLog
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: log.level.icon)
                    .foregroundColor(log.level.color)
                    .frame(width: 16)
                
                Text(log.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.message)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(log.level.color)
                        .textSelection(.enabled)
                    
                    if let details = log.details {
                        DisclosureGroup(isExpanded: $isExpanded) {
                            Text(details)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                                .textSelection(.enabled)
                                .padding(.leading, 16)
                                .padding(.vertical, 4)
                        } label: {
                            Text("Show details")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 2)
            
            Divider()
                .opacity(0.3)
        }
    }
}
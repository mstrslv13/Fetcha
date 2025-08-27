import SwiftUI

struct DebugHistoryPanel: View {
    @StateObject private var logger = PersistentDebugLogger.shared
    @State private var selectedSessionId: UUID?
    @State private var filterLevel: PersistentDebugLogger.DebugLog.LogLevel?
    @State private var searchText = ""
    
    var filteredLogs: [PersistentDebugLogger.DebugLog] {
        let logsToFilter = selectedSessionId != nil ? 
            logger.getLogsForSession(selectedSessionId!) : logger.logs
        
        return logsToFilter.filter { log in
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
                Text("History")
                    .font(.headline)
                Spacer()
                
                Menu {
                    Button("Clear Current Session") {
                        logger.clear()
                    }
                    Button("Clear All History") {
                        logger.clearAll()
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
                .help("Clear debug history")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search logs...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            
            // Filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    FilterChip(
                        title: "All",
                        isSelected: filterLevel == nil
                    ) {
                        filterLevel = nil
                    }
                    
                    ForEach(PersistentDebugLogger.DebugLog.LogLevel.allCases, id: \.self) { level in
                        FilterChip(
                            title: level.rawValue.capitalized,
                            icon: level.icon,
                            color: level.color,
                            isSelected: filterLevel == level
                        ) {
                            filterLevel = level
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            
            Divider()
            
            // Session selector
            if !logger.sessionLogs.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sessions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.top, 4)
                    
                    ScrollView {
                        VStack(spacing: 2) {
                            // Current session
                            SessionRow(
                                session: PersistentDebugLogger.SessionLog(
                                    id: logger.sessionLogs.first?.id ?? UUID(),
                                    startTime: Date(),
                                    endTime: nil,
                                    logCount: logger.logs.filter { 
                                        $0.sessionId == logger.sessionLogs.first?.id 
                                    }.count
                                ),
                                isSelected: selectedSessionId == nil,
                                isCurrent: true
                            ) {
                                selectedSessionId = nil
                            }
                            
                            // Previous sessions
                            ForEach(logger.sessionLogs.dropFirst()) { session in
                                SessionRow(
                                    session: session,
                                    isSelected: selectedSessionId == session.id,
                                    isCurrent: false
                                ) {
                                    selectedSessionId = session.id
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: 150)
                }
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
            }
            
            // Logs list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(filteredLogs) { log in
                        LogRow(log: log)
                    }
                }
                .padding(4)
            }
            
            // Footer with log count
            HStack {
                Text("\(filteredLogs.count) logs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct SessionRow: View {
    let session: PersistentDebugLogger.SessionLog
    let isSelected: Bool
    let isCurrent: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isCurrent ? "circle.fill" : "clock")
                    .foregroundColor(isCurrent ? .green : .secondary)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.startTime, style: .time)
                        .font(.caption)
                        .fontWeight(isCurrent ? .medium : .regular)
                    
                    HStack {
                        Text("\(session.logCount) logs")
                        Text("•")
                        Text(session.formattedDuration)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }
}

struct LogRow: View {
    let log: PersistentDebugLogger.DebugLog
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 6) {
                Image(systemName: log.level.icon)
                    .foregroundColor(log.level.color)
                    .font(.caption)
                    .frame(width: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.message)
                        .font(.caption)
                        .lineLimit(isExpanded ? nil : 2)
                    
                    if let details = log.details, (isExpanded || log.details!.count < 50) {
                        Text(details)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(isExpanded ? nil : 2)
                    }
                    
                    Text(log.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(Color.secondary.opacity(0.6))
                }
                
                Spacer()
                
                if log.details != nil && log.details!.count > 50 {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
    }
}

struct FilterChip: View {
    let title: String
    var icon: String? = nil
    var color: Color = .primary
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption2)
                }
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(isSelected ? .white : color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}
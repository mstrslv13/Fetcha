import Foundation
import SwiftUI

// Enhanced DebugLogger with persistent storage
class PersistentDebugLogger: ObservableObject {
    static let shared = PersistentDebugLogger()
    
    @Published var logs: [DebugLog] = []
    @Published var sessionLogs: [SessionLog] = []
    
    private let maxLogs = 10000  // Keep more logs in memory
    private let maxSessionLogs = 50  // Keep 50 sessions
    private let logFile: URL
    private let sessionFile: URL
    private let currentSessionId = UUID()
    private var currentSessionStartTime = Date()
    
    struct DebugLog: Identifiable, Codable {
        let id: UUID
        let sessionId: UUID
        let timestamp: Date
        let level: LogLevel
        let message: String
        let details: String?
        
        init(sessionId: UUID, timestamp: Date, level: LogLevel, message: String, details: String? = nil) {
            self.id = UUID()
            self.sessionId = sessionId
            self.timestamp = timestamp
            self.level = level
            self.message = message
            self.details = details
        }
        
        enum LogLevel: String, Codable, CaseIterable {
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
    
    struct SessionLog: Identifiable, Codable {
        let id: UUID
        let startTime: Date
        let endTime: Date?
        let logCount: Int
        
        var formattedDuration: String {
            guard let endTime = endTime else { return "Active" }
            let duration = endTime.timeIntervalSince(startTime)
            let hours = Int(duration) / 3600
            let minutes = (Int(duration) % 3600) / 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        }
    }
    
    private init() {
        // Create log directory in Application Support
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                  in: .userDomainMask).first!
        let logFolder = appSupport.appendingPathComponent("fetcha.stream/logs", isDirectory: true)
        
        // Create directory if needed
        try? FileManager.default.createDirectory(at: logFolder, 
                                                withIntermediateDirectories: true)
        
        logFile = logFolder.appendingPathComponent("debug_logs.json")
        sessionFile = logFolder.appendingPathComponent("sessions.json")
        
        // Load existing logs
        loadLogs()
        
        // Start new session
        startNewSession()
    }
    
    func log(_ message: String, level: DebugLog.LogLevel = .info, details: String? = nil) {
        DispatchQueue.main.async {
            let log = DebugLog(
                sessionId: self.currentSessionId,
                timestamp: Date(),
                level: level,
                message: message,
                details: details
            )
            
            self.logs.insert(log, at: 0)
            
            // Keep only recent logs in memory
            if self.logs.count > self.maxLogs {
                self.logs = Array(self.logs.prefix(self.maxLogs))
            }
            
            // Save to disk asynchronously
            self.saveLogs()
            
            // Also use the original DebugLogger for compatibility
            let originalLevel: DebugLogger.DebugLog.LogLevel = switch level {
            case .info: .info
            case .warning: .warning
            case .error: .error
            case .success: .success
            case .command: .command
            }
            DebugLogger.shared.log(message, level: originalLevel, details: details)
        }
    }
    
    func clear() {
        DispatchQueue.main.async {
            self.logs.removeAll()
            self.saveLogs()
        }
    }
    
    func clearAll() {
        logs.removeAll()
        sessionLogs.removeAll()
        try? FileManager.default.removeItem(at: logFile)
        try? FileManager.default.removeItem(at: sessionFile)
    }
    
    private func startNewSession() {
        let session = SessionLog(
            id: currentSessionId,
            startTime: currentSessionStartTime,
            endTime: nil,
            logCount: 0
        )
        sessionLogs.insert(session, at: 0)
        
        // Keep only recent sessions
        if sessionLogs.count > maxSessionLogs {
            sessionLogs = Array(sessionLogs.prefix(maxSessionLogs))
        }
        
        saveSessions()
        
        log("Session started", level: .success)
    }
    
    func endSession() {
        if let index = sessionLogs.firstIndex(where: { $0.id == currentSessionId }) {
            let logCount = logs.filter { $0.sessionId == currentSessionId }.count
            sessionLogs[index] = SessionLog(
                id: currentSessionId,
                startTime: currentSessionStartTime,
                endTime: Date(),
                logCount: logCount
            )
            saveSessions()
        }
    }
    
    func getLogsForSession(_ sessionId: UUID) -> [DebugLog] {
        logs.filter { $0.sessionId == sessionId }
    }
    
    private func loadLogs() {
        // Load logs from disk
        guard FileManager.default.fileExists(atPath: logFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: logFile)
            logs = try JSONDecoder().decode([DebugLog].self, from: data)
        } catch {
            print("Failed to load logs: \(error)")
        }
        
        // Load sessions
        guard FileManager.default.fileExists(atPath: sessionFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: sessionFile)
            sessionLogs = try JSONDecoder().decode([SessionLog].self, from: data)
        } catch {
            print("Failed to load sessions: \(error)")
        }
    }
    
    private func saveLogs() {
        // Save logs to disk in background
        Task.detached {
            do {
                let data = try JSONEncoder().encode(self.logs)
                try data.write(to: self.logFile)
            } catch {
                print("Failed to save logs: \(error)")
            }
        }
    }
    
    private func saveSessions() {
        // Save sessions to disk in background
        Task.detached {
            do {
                let data = try JSONEncoder().encode(self.sessionLogs)
                try data.write(to: self.sessionFile)
            } catch {
                print("Failed to save sessions: \(error)")
            }
        }
    }
}
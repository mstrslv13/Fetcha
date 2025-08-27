import Foundation
import AppKit

/// Manages all spawned processes to prevent runaway processes
@MainActor
class ProcessManager: ObservableObject {
    static let shared = ProcessManager()
    
    private var activeProcesses: Set<Process> = []
    private let processQueue = DispatchQueue(label: "com.ytdlpmax.processmanager", attributes: .concurrent)
    
    private init() {
        // Register for app termination notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
    }
    
    /// Register a process for tracking
    func register(_ process: Process) {
        processQueue.async(flags: .barrier) {
            self.activeProcesses.insert(process)
        }
    }
    
    /// Unregister a process (when it completes or is terminated)
    func unregister(_ process: Process) {
        processQueue.async(flags: .barrier) {
            self.activeProcesses.remove(process)
        }
    }
    
    /// Terminate a specific process with timeout
    func terminate(_ process: Process, timeout: TimeInterval = 5.0) {
        guard process.isRunning else {
            unregister(process)
            return
        }
        
        // First try graceful termination
        process.terminate()
        
        // Wait for termination with timeout
        DispatchQueue.global().async {
            let deadline = Date().addingTimeInterval(timeout)
            
            while process.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.1)
            }
            
            // Force kill if still running
            if process.isRunning {
                process.interrupt() // Try interrupt
                Thread.sleep(forTimeInterval: 0.5)
                
                if process.isRunning {
                    // Last resort: kill -9
                    let killProcess = Process()
                    killProcess.executableURL = URL(fileURLWithPath: "/bin/kill")
                    killProcess.arguments = ["-9", "\(process.processIdentifier)"]
                    try? killProcess.run()
                }
            }
            
            Task { @MainActor in
                self.unregister(process)
            }
        }
    }
    
    /// Terminate all active processes
    func terminateAll() {
        processQueue.sync {
            for process in activeProcesses {
                terminate(process, timeout: 2.0)
            }
        }
    }
    
    /// Get count of active processes
    var activeCount: Int {
        processQueue.sync {
            activeProcesses.count
        }
    }
    
    @objc private func appWillTerminate() {
        // Kill all processes when app quits
        terminateAll()
    }
    
    deinit {
        Task { @MainActor in
            terminateAll()
        }
    }
}

/// Extension to make Process run with timeout
extension Process {
    /// Run process with automatic timeout and cleanup
    func runWithTimeout(
        timeout: TimeInterval = 300, // 5 minutes default
        onTimeout: (() -> Void)? = nil
    ) async throws {
        // Register with ProcessManager
        await ProcessManager.shared.register(self)
        
        // Start the process
        try self.run()
        
        // Create timeout task
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            
            if self.isRunning {
                PersistentDebugLogger.shared.log(
                    "Process timed out after \(timeout) seconds",
                    level: .warning,
                    details: "Command: \(self.executableURL?.path ?? "unknown")"
                )
                
                await ProcessManager.shared.terminate(self)
                onTimeout?()
            }
        }
        
        // Wait for process to complete
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                self.waitUntilExit()
                continuation.resume()
            }
        }
        
        // Cancel timeout if process completed
        timeoutTask.cancel()
        
        // Unregister from ProcessManager
        await ProcessManager.shared.unregister(self)
    }
    
    /// Safely clean up process pipes
    func cleanupPipes() {
        if let outputPipe = self.standardOutput as? Pipe {
            outputPipe.fileHandleForReading.readabilityHandler = nil
            try? outputPipe.fileHandleForReading.close()
        }
        
        if let errorPipe = self.standardError as? Pipe {
            errorPipe.fileHandleForReading.readabilityHandler = nil
            try? errorPipe.fileHandleForReading.close()
        }
        
        if let inputPipe = self.standardInput as? Pipe {
            try? inputPipe.fileHandleForWriting.close()
        }
    }
}
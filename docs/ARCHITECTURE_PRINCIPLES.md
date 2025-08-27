# Architecture Principles for Current Development

> **PURPOSE**: These principles should be followed during Phase 4-5 development to ensure the codebase is ready for future evolution without requiring major refactoring.

## Core Principles

### 1. 🎯 **Separation of Concerns**

#### Current Implementation
```swift
// ❌ BAD: Mixing concerns
class DownloadManager {
    func downloadVideo(url: String) {
        // Fetching metadata
        // Managing queue
        // Handling storage
        // UI updates
        // All in one place!
    }
}

// ✅ GOOD: Separated responsibilities
class DownloadManager {
    let metadataService: MetadataService
    let queueService: QueueService
    let storageService: StorageService
    
    func downloadVideo(url: String) async {
        let metadata = await metadataService.fetch(url)
        let task = await queueService.add(metadata)
        await storageService.save(task)
    }
}
```

### 2. 🔌 **Dependency Injection**

#### Why It Matters
Future API server needs to manage service lifecycle and inject different implementations.

#### Implementation Pattern
```swift
// Define protocols for all services
protocol DownloadServiceProtocol {
    func download(url: String) async throws -> URL
}

// Inject dependencies, don't create them
class QueueViewModel: ObservableObject {
    private let downloadService: DownloadServiceProtocol
    
    init(downloadService: DownloadServiceProtocol = DownloadService.shared) {
        self.downloadService = downloadService
    }
}
```

### 3. 📢 **Event-Driven Architecture**

#### Why It Matters
Automation platforms need to react to application events.

#### Implementation Now
```swift
// Define a central event bus
enum AppEvent {
    case downloadQueued(id: UUID, url: String)
    case downloadStarted(id: UUID)
    case downloadProgress(id: UUID, progress: Double)
    case downloadCompleted(id: UUID, file: URL)
    case downloadFailed(id: UUID, error: Error)
    case metadataFetched(id: UUID, metadata: VideoInfo)
}

class EventBus {
    static let shared = EventBus()
    private let subject = PassthroughSubject<AppEvent, Never>()
    
    var publisher: AnyPublisher<AppEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func emit(_ event: AppEvent) {
        subject.send(event)
        // Future: This will also send to webhooks, API clients, etc.
    }
}

// Use throughout the app
EventBus.shared.emit(.downloadCompleted(id: task.id, file: fileURL))
```

### 4. 💾 **Storage Abstraction**

#### Why It Matters
Future cloud storage integration requires swappable backends.

#### Implementation Pattern
```swift
// Abstract storage operations
protocol StorageProvider {
    func save(_ data: Data, to path: String) async throws -> URL
    func load(from path: String) async throws -> Data
    func delete(at path: String) async throws
    func exists(at path: String) async -> Bool
    func list(at path: String) async throws -> [String]
}

// Current implementation
class LocalStorageProvider: StorageProvider {
    func save(_ data: Data, to path: String) async throws -> URL {
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
        return url
    }
}

// Future implementations without changing app code
class S3StorageProvider: StorageProvider { }
class DropboxStorageProvider: StorageProvider { }
```

### 5. 🏗️ **Service Layer Pattern**

#### Structure All Services Similarly
```swift
protocol ServiceProtocol {
    var identifier: String { get }
    func initialize() async throws
    func shutdown() async
    var isHealthy: Bool { get }
}

class YTDLPService: ServiceProtocol {
    let identifier = "com.fetcha.ytdlp"
    
    func initialize() async throws {
        // Setup code
    }
    
    func shutdown() async {
        // Cleanup code
    }
    
    var isHealthy: Bool {
        // Check if yt-dlp is available
        return findYTDLP() != nil
    }
}
```

### 6. 🔄 **State Management**

#### Centralized, Observable State
```swift
// Single source of truth for app state
@MainActor
class AppState: ObservableObject {
    @Published var queue: [QueueItem] = []
    @Published var currentDownloads: [UUID: DownloadProgress] = [:]
    @Published var preferences: AppPreferences
    @Published var integrations: [Integration] = []
    
    // Future: This becomes the API's data model
    func toJSON() -> Data {
        // Serialize current state
    }
    
    func update(from json: Data) {
        // Update from API calls
    }
}
```

### 7. 🔐 **Configuration Management**

#### Prepare for Multiple Environments
```swift
struct AppConfiguration {
    // Current: Read from UserDefaults
    // Future: Can be overridden by environment, config file, or API
    
    static var current: AppConfiguration {
        if let envConfig = ProcessInfo.processInfo.environment["FETCHA_CONFIG"] {
            return AppConfiguration(from: envConfig)
        }
        return AppConfiguration(from: UserDefaults.standard)
    }
    
    let downloadPath: String
    let maxConcurrent: Int
    let apiEnabled: Bool
    let apiPort: Int
    // Easy to add new config without breaking
}
```

### 8. 🧩 **Plugin-Ready Architecture**

#### Design Extension Points Now
```swift
// Define plugin interfaces
protocol DownloadPlugin {
    func willStartDownload(task: DownloadTask) async throws
    func didCompleteDownload(task: DownloadTask, file: URL) async
    func shouldRetry(task: DownloadTask, error: Error) -> Bool
}

// Plugin manager (simple now, powerful later)
class PluginManager {
    private var plugins: [DownloadPlugin] = []
    
    func register(_ plugin: DownloadPlugin) {
        plugins.append(plugin)
    }
    
    func notifyWillStart(_ task: DownloadTask) async {
        for plugin in plugins {
            try? await plugin.willStartDownload(task: task)
        }
    }
}
```

### 9. 🔀 **Async/Await Everywhere**

#### Future-Proof Concurrency
```swift
// Use async/await for all I/O operations
class MetadataService {
    func fetchMetadata(for url: String) async throws -> VideoInfo {
        // Already async for future network calls
    }
}

// Use AsyncSequence for streams
func downloadProgress() -> AsyncStream<DownloadProgress> {
    AsyncStream { continuation in
        // Stream progress updates
        // Future: Can be consumed by WebSocket clients
    }
}
```

### 10. 📊 **Metrics & Logging**

#### Build Observability In
```swift
class MetricsCollector {
    static let shared = MetricsCollector()
    
    func record(_ metric: Metric) {
        // Current: Debug log
        // Future: Send to analytics, monitoring
        DebugLogger.shared.log("\(metric)", level: .info)
    }
}

enum Metric {
    case downloadStarted(url: String)
    case downloadCompleted(duration: TimeInterval, size: Int64)
    case errorOccurred(error: String)
    case apiCallReceived(endpoint: String)
}
```

## Practical Guidelines for Phase 4-5

### ✅ **DO** Right Now

1. **Extract hardcoded values** into configuration
2. **Use protocols** for all services
3. **Emit events** for state changes
4. **Abstract file operations** behind interfaces
5. **Keep UI and business logic** separated
6. **Write services** as if they'll run remotely
7. **Use dependency injection** for testability
8. **Document API-like interfaces** in code

### ❌ **DON'T** Do

1. **Don't hardcode** paths, URLs, or credentials
2. **Don't create** tight coupling between components
3. **Don't skip** error handling - future API needs it
4. **Don't assume** single-user, single-device
5. **Don't mix** UI updates with business logic
6. **Don't forget** to emit events for automation

## Implementation Checklist for Current Files

### YTDLPService.swift
- [x] Protocol extraction (create YTDLPServiceProtocol)
- [ ] Event emission for all state changes
- [ ] Health check method
- [ ] Metric collection
- [ ] Error codes for API responses

### DownloadQueue.swift
- [ ] Storage provider abstraction
- [ ] Event emission for queue changes
- [ ] Serialization support (toJSON/fromJSON)
- [ ] Plugin hooks for queue operations
- [ ] Priority queue support

### ContentView.swift
- [ ] Separate business logic into ViewModels
- [ ] Remove direct service access
- [ ] Use dependency injection
- [ ] Prepare for headless mode

### AppPreferences.swift
- [ ] Configuration provider abstraction
- [ ] Environment variable support
- [ ] Export/import functionality
- [ ] Validation methods

## Migration Path Examples

### Example: Making Storage Pluggable

#### Step 1: Create Protocol (Phase 4)
```swift
protocol StorageProvider {
    func save(_ data: Data, to path: String) async throws -> URL
}
```

#### Step 2: Implement Current Behavior (Phase 4)
```swift
class LocalStorageProvider: StorageProvider {
    func save(_ data: Data, to path: String) async throws -> URL {
        // Current implementation
    }
}
```

#### Step 3: Use Protocol (Phase 5)
```swift
class DownloadService {
    let storage: StorageProvider // Not LocalStorageProvider!
}
```

#### Step 4: Add New Providers (Evolution)
```swift
class S3StorageProvider: StorageProvider {
    // New implementation, no changes needed elsewhere
}
```

## Testing Considerations

### Write Tests for Interfaces
```swift
// Test the protocol, not the implementation
func testStorageProvider<T: StorageProvider>(_ provider: T) async {
    // This test works for ANY storage provider
}
```

### Mock Services Easily
```swift
class MockDownloadService: DownloadServiceProtocol {
    // Easy to create for testing
}
```

## Summary

Following these principles during Phase 4-5 will:
1. **Prevent technical debt** accumulation
2. **Enable smooth evolution** to the ambitious vision
3. **Maintain code quality** as complexity grows
4. **Support future features** without rewrites
5. **Keep the codebase** testable and maintainable

Remember: **We're building a platform, not just an app.**

---

*Apply these principles incrementally. Perfect is the enemy of good, but good architecture is the friend of future features.*
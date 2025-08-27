import Foundation

// FUTURE: Evolution Stage B - Storage abstraction for cloud provider integration
// This protocol defines the interface that all storage providers must implement
// Currently only LocalStorageProvider is implemented, but this allows easy addition of
// Dropbox, Google Drive, S3, etc. without changing the core download logic

protocol StorageProvider {
    func save(data: Data, to path: String) async throws -> String
    func load(from path: String) async throws -> Data
    func delete(at path: String) async throws
    func list(at path: String) async throws -> [String]
    func exists(at path: String) async -> Bool
    func createDirectory(at path: String) async throws
}

// Current implementation - local file system
class LocalStorageProvider: StorageProvider {
    private let fileManager = FileManager.default
    
    func save(data: Data, to path: String) async throws -> String {
        let url = URL(fileURLWithPath: path)
        try data.write(to: url)
        return path
    }
    
    func load(from path: String) async throws -> Data {
        let url = URL(fileURLWithPath: path)
        return try Data(contentsOf: url)
    }
    
    func delete(at path: String) async throws {
        let url = URL(fileURLWithPath: path)
        try fileManager.removeItem(at: url)
    }
    
    func list(at path: String) async throws -> [String] {
        let url = URL(fileURLWithPath: path)
        return try fileManager.contentsOfDirectory(atPath: url.path)
    }
    
    func exists(at path: String) async -> Bool {
        fileManager.fileExists(atPath: path)
    }
    
    func createDirectory(at path: String) async throws {
        let url = URL(fileURLWithPath: path)
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }
}

// FUTURE: Evolution Stage B - Cloud storage providers
// These will be implemented when cloud integration is added

/*
class DropboxStorageProvider: StorageProvider {
    // Implementation will use Dropbox SDK
    // Requires OAuth2 authentication flow
}

class GoogleDriveStorageProvider: StorageProvider {
    // Implementation will use Google Drive API
    // Requires Google Sign-In
}

class S3StorageProvider: StorageProvider {
    // Implementation will use AWS SDK
    // Requires AWS credentials configuration
}

class WebDAVStorageProvider: StorageProvider {
    // Implementation for NextCloud, ownCloud, etc.
    // Requires WebDAV protocol implementation
}
*/

// Storage manager to handle provider selection
class StorageManager {
    static let shared = StorageManager()
    
    private var providers: [String: StorageProvider] = [
        "local": LocalStorageProvider()
    ]
    
    private var defaultProvider = "local"
    
    private init() {}
    
    func getProvider(_ name: String? = nil) -> StorageProvider {
        let providerName = name ?? defaultProvider
        return providers[providerName] ?? LocalStorageProvider()
    }
    
    // FUTURE: Evolution Stage B - Provider registration
    // func registerProvider(_ name: String, provider: StorageProvider)
    // func setDefaultProvider(_ name: String)
    // func listProviders() -> [String]
}
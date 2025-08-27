import Foundation
import Combine

// FUTURE: Phase 5 / Evolution Stage A - Event-driven architecture foundation
// This minimal event bus will enable future API integration and cross-component communication
// Currently unused but provides the foundation for future features without technical debt

enum AppEvent {
    case downloadStarted(url: String, id: UUID)
    case downloadProgress(id: UUID, progress: Double)
    case downloadCompleted(id: UUID, filePath: String)
    case downloadFailed(id: UUID, error: Error)
    case queueUpdated
    case metadataFetched(url: String, info: VideoInfo)
    case cookiesUpdated(browser: String)
    
    // FUTURE: Evolution Stage A - API server events
    // case apiRequestReceived(endpoint: String, params: [String: Any])
    // case apiResponseSent(endpoint: String, status: Int)
    
    // FUTURE: Evolution Stage B - Cloud storage events  
    // case uploadStarted(provider: String, file: String)
    // case uploadCompleted(provider: String, file: String)
    
    // FUTURE: Evolution Stage C - Semantic search events
    // case semanticIndexingStarted(file: String)
    // case semanticSearchQuery(query: String)
}

class EventBus: ObservableObject {
    static let shared = EventBus()
    
    private let subject = PassthroughSubject<AppEvent, Never>()
    
    var publisher: AnyPublisher<AppEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    private init() {}
    
    func publish(_ event: AppEvent) {
        subject.send(event)
    }
    
    // FUTURE: Phase 5 - Add event filtering and subscription management
    // func subscribe(to eventType: AppEvent.Type, handler: @escaping (AppEvent) -> Void)
    // func unsubscribe(id: UUID)
}
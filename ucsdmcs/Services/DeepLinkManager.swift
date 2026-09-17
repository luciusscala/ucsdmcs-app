import Foundation

@Observable
final class DeepLinkManager {
    var pendingEventID: UUID?

    func handle(url: URL) {
        // Expected format: ucsdmcs://event/{eventID}
        // NOT DEPLOYED YET
        guard url.scheme == "ucsdmcs",
              url.host == "event",
              let eventIdString = url.pathComponents.dropFirst().first,
              let eventId = UUID(uuidString: eventIdString) else {
            return
        }
        pendingEventID = eventId
    }
}

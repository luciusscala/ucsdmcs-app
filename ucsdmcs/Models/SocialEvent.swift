import Foundation

struct SocialEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let description: String?
    let eventId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, description
        case eventId = "event_id"
    }
}

import Foundation

struct Practice: Identifiable, Codable, Hashable {
    let id: UUID
    let eventId: UUID
    let fieldId: UUID
    let notes: String?
    let filmLink: String?

    // Nested field from Supabase join
    let fields: Field?

    enum CodingKeys: String, CodingKey {
        case id, notes, fields
        case eventId = "event_id"
        case fieldId = "field_id"
        case filmLink = "film_link"
    }
}

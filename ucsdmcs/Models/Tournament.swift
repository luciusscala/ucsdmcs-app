import Foundation

struct Tournament: Identifiable, Codable, Hashable {
    let id: UUID
    let eventId: UUID
    let name: String
    let websiteLink: String?
    let location: String?
    let fieldId: UUID?

    // Nested join
    let fields: Field?

    enum CodingKeys: String, CodingKey {
        case id, name, location, fields
        case eventId = "event_id"
        case websiteLink = "website_link"
        case fieldId = "field_id"
    }
}

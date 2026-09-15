import Foundation

struct Season: Identifiable, Codable, Hashable {
    let id: UUID
    let year: Int
    let isCurrent: Bool

    enum CodingKeys: String, CodingKey {
        case id, year
        case isCurrent = "is_current"
    }
}

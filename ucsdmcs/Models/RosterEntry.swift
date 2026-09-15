import Foundation

struct RosterEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let personId: UUID
    let seasonId: UUID
    let playerClass: String
    let position: String
    let number: Int?

    // Nested person from Supabase join: roster(*, people(*))
    let people: Person?

    var displayName: String {
        people?.name ?? "Unknown"
    }

    var displayNumber: String? {
        number.map { "#\($0)" }
    }

    enum CodingKeys: String, CodingKey {
        case id, position, number, people
        case personId = "person_id"
        case seasonId = "season_id"
        case playerClass = "class"
    }
}

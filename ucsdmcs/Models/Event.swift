import Foundation

struct Event: Identifiable, Codable, Hashable {
    let id: UUID
    let seasonId: UUID
    let eventType: String
    let eventDate: Date

    enum CodingKeys: String, CodingKey {
        case id
        case seasonId = "season_id"
        case eventType = "event_type"
        case eventDate = "event_date"
    }

    var typeLabel: String {
        switch eventType {
        case "practice": return "Practice"
        case "game": return "Game"
        case "social": return "Social"
        case "tournament": return "Tournament"
        default: return eventType.capitalized
        }
    }

    var typeIcon: String {
        switch eventType {
        case "practice": return "figure.run"
        case "game": return "sportscourt.fill"
        case "social": return "party.popper.fill"
        case "tournament": return "trophy.fill"
        default: return "calendar"
        }
    }
}

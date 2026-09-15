import Foundation

struct Game: Identifiable, Codable, Hashable {
    let id: UUID
    let opponentId: UUID
    let isHome: Bool
    let ourScore: Int?
    let theirScore: Int?
    let fieldId: UUID?
    let eventId: UUID?
    let filmLink: String?
    let tournamentId: UUID?

    // Nested joins from Supabase
    let fields: Field?
    let teams: Team?

    enum CodingKeys: String, CodingKey {
        case id, fields, teams
        case opponentId = "opponent_id"
        case isHome = "is_home"
        case ourScore = "our_score"
        case theirScore = "their_score"
        case fieldId = "field_id"
        case eventId = "event_id"
        case filmLink = "film_link"
        case tournamentId = "tournament_id"
    }

    var opponentName: String {
        teams?.name ?? "TBD"
    }

    var title: String {
        let prefix = isHome ? "vs." : "@"
        return "\(prefix) \(opponentName)"
    }
}

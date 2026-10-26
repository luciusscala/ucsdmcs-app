import Foundation

struct Game: Identifiable, Codable, Hashable {
    let id: UUID
    let homeTeamId: UUID
    let awayTeamId: UUID
    let homeTeamScore: Int?
    let awayTeamScore: Int?
    let isNeutral: Bool?
    let fieldId: UUID?
    let eventId: UUID?
    let filmLink: String?
    let tournamentId: UUID?

    // Nested joins from Supabase (aliased)
    let fields: Field?
    let homeTeam: Team?
    let awayTeam: Team?

    // Set by DataService after decode — NOT part of CodingKeys
    var myTeamId: UUID = UUID()

    enum CodingKeys: String, CodingKey {
        case id, fields
        case homeTeamId = "home_team_id"
        case awayTeamId = "away_team_id"
        case homeTeamScore = "home_team_score"
        case awayTeamScore = "away_team_score"
        case isNeutral = "is_neutral"
        case fieldId = "field_id"
        case eventId = "event_id"
        case filmLink = "film_link"
        case tournamentId = "tournament_id"
        case homeTeam = "home_team"
        case awayTeam = "away_team"
    }

    // MARK: - Computed properties (preserve existing view API)

    var isHome: Bool {
        myTeamId == homeTeamId
    }

    var opponentId: UUID {
        isHome ? awayTeamId : homeTeamId
    }

    var opponent: Team? {
        isHome ? awayTeam : homeTeam
    }

    var opponentName: String {
        opponent?.name ?? "TBD"
    }

    var title: String {
        let prefix = isHome ? "vs." : "@"
        return "\(prefix) \(opponentName)"
    }

    var ourScore: Int? {
        isHome ? homeTeamScore : awayTeamScore
    }

    var theirScore: Int? {
        isHome ? awayTeamScore : homeTeamScore
    }

    // MARK: - Hashable (exclude mutable myTeamId from identity)

    static func == (lhs: Game, rhs: Game) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

import Foundation

struct Team: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let logoPath: String?
    let dataAlias: String?
    let teamCode: String?
    let adminCode: String?
    let orgId: UUID?
    let sportId: UUID?
    let division: String?

    enum CodingKeys: String, CodingKey {
        case id, name, division
        case logoPath = "logo_path"
        case dataAlias = "data_alias"
        case teamCode = "team_code"
        case adminCode = "admin_code"
        case orgId = "org_id"
        case sportId = "sport_id"
    }
}

import Foundation

struct Team: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let logoPath: String?
    let dataAlias: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case logoPath = "logo_path"
        case dataAlias = "data_alias"
    }
}

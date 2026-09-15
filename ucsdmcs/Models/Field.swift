import Foundation

struct Field: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let area: String?
    let mapsAddress: String?
    let picturePath: String?
    let recommendedParking: String?

    enum CodingKeys: String, CodingKey {
        case id, name, area
        case mapsAddress = "maps_address"
        case picturePath = "picture_path"
        case recommendedParking = "recommended_parking"
    }
}

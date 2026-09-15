import Foundation

struct Person: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let hometown: String?
    let picturePath: String?

    enum CodingKeys: String, CodingKey {
        case id, name, hometown
        case picturePath = "picture_path"
    }
}

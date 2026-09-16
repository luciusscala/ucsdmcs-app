import Foundation

struct Person: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let hometown: String?
    let picturePath: String?
    let phone: String?

    enum CodingKeys: String, CodingKey {
        case id, name, hometown, phone
        case picturePath = "picture_path"
    }
}

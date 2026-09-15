import SwiftUI

enum AvailabilityStatus: String, Codable, CaseIterable, Hashable {
    case yes
    case no

    var label: String {
        switch self {
        case .yes: return "Going"
        case .no: return "Not Going"
        }
    }

    var icon: String {
        switch self {
        case .yes: return "checkmark.circle.fill"
        case .no: return "xmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .yes: return Color("availabilityGreen")
        case .no: return Color("availabilityRed")
        }
    }
}

struct Availability: Identifiable, Codable, Hashable {
    let id: UUID
    let eventId: UUID
    let rosterId: UUID
    let status: AvailabilityStatus
    let updatedAt: Date?

    // Nested join: availability(*, roster(*, people(*)))
    let roster: RosterEntry?

    enum CodingKeys: String, CodingKey {
        case id, status, roster
        case eventId = "event_id"
        case rosterId = "roster_id"
        case updatedAt = "updated_at"
    }
}

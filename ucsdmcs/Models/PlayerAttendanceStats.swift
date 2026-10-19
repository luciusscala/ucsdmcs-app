import Foundation

struct PlayerAttendanceStats: Identifiable {
    let rosterEntry: RosterEntry
    let totalEvents: Int
    let goingCount: Int
    let notGoingCount: Int
    let noResponseCount: Int

    var id: UUID { rosterEntry.id }

    var displayName: String { rosterEntry.displayName }
    var displayNumber: String? { rosterEntry.displayNumber }

    var responseRate: Double {
        guard totalEvents > 0 else { return 1.0 }
        return Double(goingCount + notGoingCount) / Double(totalEvents)
    }

    var attendanceRate: Double {
        guard totalEvents > 0 else { return 1.0 }
        return Double(goingCount) / Double(totalEvents)
    }

    var noResponseRate: Double {
        guard totalEvents > 0 else { return 0 }
        return Double(noResponseCount) / Double(totalEvents)
    }

    /// Composite score for sorting. Higher = more concerning.
    /// No-response weighted higher than declining (ghosting is worse than saying no).
    var issueScore: Double {
        noResponseRate * 1.5 + (totalEvents > 0 ? Double(notGoingCount) / Double(totalEvents) : 0)
    }
}

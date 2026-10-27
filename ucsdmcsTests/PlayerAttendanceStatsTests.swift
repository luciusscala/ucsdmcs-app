import Testing
import Foundation
@testable import ucsdmcs

struct PlayerAttendanceStatsTests {

    static let roster = RosterEntry(
        id: UUID(), personId: UUID(), seasonId: UUID(), teamId: UUID(),
        playerClass: "Junior", position: "Cutter", number: 10,
        people: Person(id: UUID(), name: "Test Player", hometown: nil, picturePath: nil, phone: nil)
    )

    static func makeStats(
        totalEvents: Int = 10,
        goingCount: Int = 5,
        notGoingCount: Int = 3,
        noResponseCount: Int = 2
    ) -> PlayerAttendanceStats {
        PlayerAttendanceStats(
            rosterEntry: roster,
            totalEvents: totalEvents,
            goingCount: goingCount,
            notGoingCount: notGoingCount,
            noResponseCount: noResponseCount
        )
    }

    // MARK: - Response Rate

    @Test func responseRateCountsBothGoingAndNotGoing() {
        let stats = Self.makeStats(totalEvents: 10, goingCount: 5, notGoingCount: 3, noResponseCount: 2)
        #expect(stats.responseRate == 0.8)
    }

    @Test func responseRateDefaultsToOneWhenNoEvents() {
        let stats = Self.makeStats(totalEvents: 0, goingCount: 0, notGoingCount: 0, noResponseCount: 0)
        #expect(stats.responseRate == 1.0)
    }

    @Test func perfectResponseRate() {
        let stats = Self.makeStats(totalEvents: 10, goingCount: 7, notGoingCount: 3, noResponseCount: 0)
        #expect(stats.responseRate == 1.0)
    }

    // MARK: - Attendance Rate

    @Test func attendanceRateIsGoingOverTotal() {
        let stats = Self.makeStats(totalEvents: 10, goingCount: 8, notGoingCount: 1, noResponseCount: 1)
        #expect(stats.attendanceRate == 0.8)
    }

    @Test func attendanceRateDefaultsToOneWhenNoEvents() {
        let stats = Self.makeStats(totalEvents: 0, goingCount: 0, notGoingCount: 0, noResponseCount: 0)
        #expect(stats.attendanceRate == 1.0)
    }

    // MARK: - No Response Rate

    @Test func noResponseRateCalculation() {
        let stats = Self.makeStats(totalEvents: 10, goingCount: 5, notGoingCount: 2, noResponseCount: 3)
        #expect(stats.noResponseRate == 0.3)
    }

    @Test func noResponseRateIsZeroWhenNoEvents() {
        let stats = Self.makeStats(totalEvents: 0, goingCount: 0, notGoingCount: 0, noResponseCount: 0)
        #expect(stats.noResponseRate == 0)
    }

    // MARK: - Issue Score

    @Test func issueScoreWeightsNoResponseHigher() {
        // noResponseRate * 1.5 + notGoingRate
        // (2/10) * 1.5 + (3/10) = 0.3 + 0.3 = 0.6
        let stats = Self.makeStats(totalEvents: 10, goingCount: 5, notGoingCount: 3, noResponseCount: 2)
        #expect(stats.issueScore == 0.6)
    }

    @Test func issueScoreZeroForPerfectAttendance() {
        let stats = Self.makeStats(totalEvents: 10, goingCount: 10, notGoingCount: 0, noResponseCount: 0)
        #expect(stats.issueScore == 0)
    }

    @Test func issueScoreHighForGhosting() {
        // All no response: (10/10) * 1.5 + 0 = 1.5
        let stats = Self.makeStats(totalEvents: 10, goingCount: 0, notGoingCount: 0, noResponseCount: 10)
        #expect(stats.issueScore == 1.5)
    }

    // MARK: - Display

    @Test func displayNameFromRoster() {
        let stats = Self.makeStats()
        #expect(stats.displayName == "Test Player")
    }

    @Test func displayNumberFromRoster() {
        let stats = Self.makeStats()
        #expect(stats.displayNumber == "#10")
    }
}

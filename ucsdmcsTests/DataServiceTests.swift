import Testing
import Foundation
@testable import ucsdmcs

/// Tests for DataService's pure in-memory composite helpers.
/// These don't hit Supabase — we set the published arrays directly.
struct DataServiceTests {

    // MARK: - Fixtures

    static let teamId = UUID()
    static let seasonId = UUID()

    static func makeRosterEntry(id: UUID = UUID(), number: Int? = nil, name: String = "Player") -> RosterEntry {
        RosterEntry(
            id: id, personId: UUID(), seasonId: seasonId, teamId: teamId,
            playerClass: "Senior", position: "Handler", number: number,
            people: Person(id: UUID(), name: name, hometown: nil, picturePath: nil, phone: nil)
        )
    }

    static func makeEvent(id: UUID = UUID(), type: String = "practice", date: Date = Date()) -> Event {
        Event(id: id, seasonId: seasonId, teamId: teamId, eventType: type, eventDate: date)
    }

    static func makeAvailability(eventId: UUID, rosterId: UUID, status: AvailabilityStatus) -> Availability {
        Availability(
            id: UUID(), eventId: eventId, rosterId: rosterId,
            status: status, updatedAt: nil, roster: nil
        )
    }

    // MARK: - eventsWithAvailability

    @Test func eventsWithAvailabilityMergesCorrectly() {
        let service = DataService()
        let event = Self.makeEvent(type: "practice")
        let rosterId = UUID()

        service.events = [event]
        service.availabilityByEvent = [
            event.id: [Self.makeAvailability(eventId: event.id, rosterId: rosterId, status: .yes)]
        ]

        let results = service.eventsWithAvailability(currentRosterId: rosterId)
        #expect(results.count == 1)
        #expect(results[0].currentRosterStatus == .yes)
        #expect(results[0].yesCount == 1)
    }

    @Test func eventsWithAvailabilityNoResponseForDifferentRoster() {
        let service = DataService()
        let event = Self.makeEvent()
        let myRosterId = UUID()
        let otherRosterId = UUID()

        service.events = [event]
        service.availabilityByEvent = [
            event.id: [Self.makeAvailability(eventId: event.id, rosterId: otherRosterId, status: .yes)]
        ]

        let results = service.eventsWithAvailability(currentRosterId: myRosterId)
        #expect(results[0].currentRosterStatus == nil)
    }

    @Test func eventsWithAvailabilityAttachesSubtypes() {
        let service = DataService()
        let gameEvent = Self.makeEvent(type: "game")
        let practiceEvent = Self.makeEvent(type: "practice")

        var game = Game(
            id: UUID(), homeTeamId: Self.teamId, awayTeamId: UUID(),
            homeTeamScore: nil, awayTeamScore: nil, isNeutral: false,
            fieldId: nil, eventId: gameEvent.id, filmLink: nil, tournamentId: nil,
            fields: nil, homeTeam: nil, awayTeam: nil
        )
        game.myTeamId = Self.teamId

        let practice = Practice(
            id: UUID(), eventId: practiceEvent.id, fieldId: UUID(),
            notes: "Warm up", filmLink: nil, fields: nil
        )

        service.events = [gameEvent, practiceEvent]
        service.games = [gameEvent.id: game]
        service.practices = [practiceEvent.id: practice]

        let results = service.eventsWithAvailability(currentRosterId: UUID())
        #expect(results[0].game != nil)
        #expect(results[0].practice == nil)
        #expect(results[1].practice != nil)
        #expect(results[1].game == nil)
    }

    // MARK: - rosterWithoutResponse

    @Test func rosterWithoutResponseFiltersCorrectly() {
        let service = DataService()
        let eventId = UUID()
        let respondedId = UUID()
        let silentId = UUID()

        service.roster = [
            Self.makeRosterEntry(id: respondedId, name: "Responded"),
            Self.makeRosterEntry(id: silentId, name: "Silent"),
        ]
        service.availabilityByEvent = [
            eventId: [Self.makeAvailability(eventId: eventId, rosterId: respondedId, status: .yes)]
        ]

        let noResponse = service.rosterWithoutResponse(eventId: eventId)
        #expect(noResponse.count == 1)
        #expect(noResponse[0].id == silentId)
    }

    @Test func rosterWithoutResponseAllResponded() {
        let service = DataService()
        let eventId = UUID()
        let rosterId = UUID()

        service.roster = [Self.makeRosterEntry(id: rosterId)]
        service.availabilityByEvent = [
            eventId: [Self.makeAvailability(eventId: eventId, rosterId: rosterId, status: .no)]
        ]

        let noResponse = service.rosterWithoutResponse(eventId: eventId)
        #expect(noResponse.isEmpty)
    }

    // MARK: - filteredSeasonEvents

    @Test func filteredSeasonEventsReturnsAllWhenNoFilter() {
        let service = DataService()
        service.allSeasonEvents = [Self.makeEvent(), Self.makeEvent()]
        #expect(service.filteredSeasonEvents().count == 2)
    }

    @Test func filteredSeasonEventsFiltersByDate() {
        let service = DataService()
        let old = Self.makeEvent(date: Date().addingTimeInterval(-86400 * 30))
        let recent = Self.makeEvent(date: Date().addingTimeInterval(-86400))
        service.allSeasonEvents = [old, recent]

        let since = Date().addingTimeInterval(-86400 * 7)
        let filtered = service.filteredSeasonEvents(since: since)
        #expect(filtered.count == 1)
        #expect(filtered[0].id == recent.id)
    }

    // MARK: - playerAttendanceStats

    @Test func playerAttendanceStatsCalculatesCorrectly() {
        let service = DataService()
        let rosterId = UUID()
        let event1 = Self.makeEvent()
        let event2 = Self.makeEvent()
        let event3 = Self.makeEvent()

        service.roster = [Self.makeRosterEntry(id: rosterId)]
        service.allSeasonEvents = [event1, event2, event3]
        service.allSeasonAvailability = [
            event1.id: [Self.makeAvailability(eventId: event1.id, rosterId: rosterId, status: .yes)],
            event2.id: [Self.makeAvailability(eventId: event2.id, rosterId: rosterId, status: .no)],
            event3.id: [], // no response
        ]

        let stats = service.playerAttendanceStats()
        #expect(stats.count == 1)
        #expect(stats[0].totalEvents == 3)
        #expect(stats[0].goingCount == 1)
        #expect(stats[0].notGoingCount == 1)
        #expect(stats[0].noResponseCount == 1)
    }

    @Test func playerAttendanceStatsSortsByIssueScore() {
        let service = DataService()
        let goodId = UUID()
        let badId = UUID()
        let event1 = Self.makeEvent()
        let event2 = Self.makeEvent()

        service.roster = [
            Self.makeRosterEntry(id: goodId, name: "Good"),
            Self.makeRosterEntry(id: badId, name: "Bad"),
        ]
        service.allSeasonEvents = [event1, event2]
        service.allSeasonAvailability = [
            event1.id: [
                Self.makeAvailability(eventId: event1.id, rosterId: goodId, status: .yes),
                // badId doesn't respond
            ],
            event2.id: [
                Self.makeAvailability(eventId: event2.id, rosterId: goodId, status: .yes),
                // badId doesn't respond
            ],
        ]

        let stats = service.playerAttendanceStats()
        // Bad player (all no-response) should be first (higher issue score)
        #expect(stats[0].displayName == "Bad")
        #expect(stats[1].displayName == "Good")
    }
}

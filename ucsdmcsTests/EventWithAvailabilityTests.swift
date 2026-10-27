import Testing
import Foundation
@testable import ucsdmcs

struct EventWithAvailabilityTests {

    // MARK: - Fixtures

    static let teamId = UUID()
    static let opponentId = UUID()

    static func makeEvent(type: String = "practice") -> Event {
        Event(id: UUID(), seasonId: UUID(), teamId: teamId, eventType: type, eventDate: Date())
    }

    static let field = Field(
        id: UUID(), name: "Warren Field", area: "Campus",
        mapsAddress: "9500 Gilman Dr", picturePath: nil, recommendedParking: nil
    )

    static func makeGame(myTeamId: UUID = teamId) -> Game {
        let opponent = Team(
            id: opponentId, name: "UCLA", logoPath: "logos/ucla.png",
            dataAlias: nil, teamCode: nil, adminCode: nil,
            orgId: nil, sportId: nil, division: nil
        )
        var game = Game(
            id: UUID(), homeTeamId: teamId, awayTeamId: opponentId,
            homeTeamScore: nil, awayTeamScore: nil, isNeutral: false,
            fieldId: field.id, eventId: nil, filmLink: nil, tournamentId: nil,
            fields: field, homeTeam: nil, awayTeam: opponent
        )
        game.myTeamId = myTeamId
        return game
    }

    static func makePractice() -> Practice {
        Practice(
            id: UUID(), eventId: UUID(), fieldId: field.id,
            notes: "Bring cleats", filmLink: nil, fields: field
        )
    }

    static func makeRosterEntry(id: UUID = UUID()) -> RosterEntry {
        RosterEntry(
            id: id, personId: UUID(), seasonId: UUID(), teamId: teamId,
            playerClass: "Senior", position: "Handler", number: 1,
            people: Person(id: UUID(), name: "Player", hometown: nil, picturePath: nil, phone: nil)
        )
    }

    static func makeAvailability(
        eventId: UUID, rosterId: UUID, status: AvailabilityStatus
    ) -> Availability {
        Availability(
            id: UUID(), eventId: eventId, rosterId: rosterId,
            status: status, updatedAt: nil, roster: nil
        )
    }

    static func makeItem(
        event: Event,
        responses: [Availability] = [],
        currentRosterStatus: AvailabilityStatus? = nil,
        practice: Practice? = nil,
        game: Game? = nil,
        socialEvent: SocialEvent? = nil,
        tournament: Tournament? = nil
    ) -> EventWithAvailability {
        var item = EventWithAvailability(
            event: event, responses: responses,
            currentRosterStatus: currentRosterStatus
        )
        item.practice = practice
        item.game = game
        item.socialEvent = socialEvent
        item.tournament = tournament
        return item
    }

    // MARK: - Title

    @Test func titleForPractice() {
        let item = Self.makeItem(event: Self.makeEvent(type: "practice"))
        #expect(item.title == "Practice")
    }

    @Test func titleForGameUsesGameTitle() {
        let game = Self.makeGame()
        let item = Self.makeItem(event: Self.makeEvent(type: "game"), game: game)
        #expect(item.title == "vs. UCLA")
    }

    @Test func titleForGameFallback() {
        let item = Self.makeItem(event: Self.makeEvent(type: "game"))
        #expect(item.title == "Game")
    }

    @Test func titleForSocial() {
        let social = SocialEvent(id: UUID(), name: "End of Season Party", description: nil, eventId: nil)
        let item = Self.makeItem(event: Self.makeEvent(type: "social"), socialEvent: social)
        #expect(item.title == "End of Season Party")
    }

    @Test func titleForTournament() {
        let tournament = Tournament(
            id: UUID(), eventId: UUID(), name: "Southwest Regionals",
            websiteLink: nil, location: nil, fieldId: nil, fields: nil
        )
        let item = Self.makeItem(event: Self.makeEvent(type: "tournament"), tournament: tournament)
        #expect(item.title == "Southwest Regionals")
    }

    // MARK: - Location

    @Test func locationForPractice() {
        let item = Self.makeItem(
            event: Self.makeEvent(type: "practice"),
            practice: Self.makePractice()
        )
        #expect(item.location == "Warren Field")
    }

    @Test func locationForGame() {
        let item = Self.makeItem(
            event: Self.makeEvent(type: "game"),
            game: Self.makeGame()
        )
        #expect(item.location == "Warren Field")
    }

    @Test func locationNilForSocial() {
        let item = Self.makeItem(event: Self.makeEvent(type: "social"))
        #expect(item.location == nil)
    }

    // MARK: - Maps Address

    @Test func mapsAddressForPractice() {
        let item = Self.makeItem(
            event: Self.makeEvent(type: "practice"),
            practice: Self.makePractice()
        )
        #expect(item.mapsAddress == "9500 Gilman Dr")
    }

    @Test func mapsAddressNilForSocial() {
        let item = Self.makeItem(event: Self.makeEvent(type: "social"))
        #expect(item.mapsAddress == nil)
    }

    // MARK: - Response Counts

    @Test func responseCounts() {
        let event = Self.makeEvent()
        let roster1 = UUID()
        let roster2 = UUID()
        let roster3 = UUID()
        let responses = [
            Self.makeAvailability(eventId: event.id, rosterId: roster1, status: .yes),
            Self.makeAvailability(eventId: event.id, rosterId: roster2, status: .yes),
            Self.makeAvailability(eventId: event.id, rosterId: roster3, status: .no),
        ]
        let item = Self.makeItem(event: event, responses: responses)
        #expect(item.yesCount == 2)
        #expect(item.noCount == 1)
        #expect(item.totalResponded == 3)
    }

    @Test func emptyResponses() {
        let item = Self.makeItem(event: Self.makeEvent())
        #expect(item.yesCount == 0)
        #expect(item.noCount == 0)
        #expect(item.totalResponded == 0)
    }

    // MARK: - Notes

    @Test func notesForPractice() {
        let item = Self.makeItem(
            event: Self.makeEvent(type: "practice"),
            practice: Self.makePractice()
        )
        #expect(item.notes == "Bring cleats")
    }

    @Test func notesForGameWithFilm() {
        var game = Self.makeGame()
        // Need a game with filmLink set — create directly
        var gameWithFilm = Game(
            id: UUID(), homeTeamId: Self.teamId, awayTeamId: Self.opponentId,
            homeTeamScore: nil, awayTeamScore: nil, isNeutral: false,
            fieldId: nil, eventId: nil, filmLink: "https://film.com/game1",
            tournamentId: nil, fields: nil, homeTeam: nil, awayTeam: nil
        )
        gameWithFilm.myTeamId = Self.teamId
        let item = Self.makeItem(event: Self.makeEvent(type: "game"), game: gameWithFilm)
        #expect(item.notes == "Film available")
    }

    @Test func notesNilForGameWithoutFilm() {
        let item = Self.makeItem(event: Self.makeEvent(type: "game"), game: Self.makeGame())
        #expect(item.notes == nil)
    }
}

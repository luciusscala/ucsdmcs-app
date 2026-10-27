import Testing
import Foundation
@testable import ucsdmcs

struct GameTests {

    // MARK: - Test Fixtures

    static let myTeamUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let opponentUUID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    static let homeTeam = Team(
        id: myTeamUUID, name: "UCSD", logoPath: "logos/ucsd.png",
        dataAlias: nil, teamCode: nil, adminCode: nil,
        orgId: nil, sportId: nil, division: nil
    )
    static let awayTeam = Team(
        id: opponentUUID, name: "UCLA", logoPath: "logos/ucla.png",
        dataAlias: nil, teamCode: nil, adminCode: nil,
        orgId: nil, sportId: nil, division: nil
    )

    static func makeGame(
        homeTeamId: UUID = myTeamUUID,
        awayTeamId: UUID = opponentUUID,
        homeTeamScore: Int? = nil,
        awayTeamScore: Int? = nil,
        isNeutral: Bool? = false,
        homeTeam: Team? = homeTeam,
        awayTeam: Team? = awayTeam,
        myTeamId: UUID = myTeamUUID
    ) -> Game {
        var game = Game(
            id: UUID(), homeTeamId: homeTeamId, awayTeamId: awayTeamId,
            homeTeamScore: homeTeamScore, awayTeamScore: awayTeamScore,
            isNeutral: isNeutral, fieldId: nil, eventId: nil,
            filmLink: nil, tournamentId: nil, fields: nil,
            homeTeam: homeTeam, awayTeam: awayTeam
        )
        game.myTeamId = myTeamId
        return game
    }

    // MARK: - Home Perspective

    @Test func isHomeWhenMyTeamIsHomeTeam() {
        let game = Self.makeGame(myTeamId: Self.myTeamUUID)
        #expect(game.isHome == true)
    }

    @Test func isAwayWhenMyTeamIsAwayTeam() {
        let game = Self.makeGame(myTeamId: Self.opponentUUID)
        #expect(game.isHome == false)
    }

    @Test func isAwayWhenMyTeamIdIsUnknown() {
        let game = Self.makeGame(myTeamId: UUID())
        #expect(game.isHome == false)
    }

    // MARK: - Opponent

    @Test func opponentIdWhenHome() {
        let game = Self.makeGame(myTeamId: Self.myTeamUUID)
        #expect(game.opponentId == Self.opponentUUID)
    }

    @Test func opponentIdWhenAway() {
        let game = Self.makeGame(myTeamId: Self.opponentUUID)
        #expect(game.opponentId == Self.myTeamUUID)
    }

    @Test func opponentTeamWhenHome() {
        let game = Self.makeGame(myTeamId: Self.myTeamUUID)
        #expect(game.opponent?.name == "UCLA")
    }

    @Test func opponentTeamWhenAway() {
        let game = Self.makeGame(myTeamId: Self.opponentUUID)
        #expect(game.opponent?.name == "UCSD")
    }

    @Test func opponentNameFallsBackToTBD() {
        let game = Self.makeGame(homeTeam: nil, awayTeam: nil)
        #expect(game.opponentName == "TBD")
    }

    // MARK: - Title

    @Test func titleShowsVsWhenHome() {
        let game = Self.makeGame(myTeamId: Self.myTeamUUID)
        #expect(game.title == "vs. UCLA")
    }

    @Test func titleShowsAtWhenAway() {
        let game = Self.makeGame(myTeamId: Self.opponentUUID)
        #expect(game.title == "@ UCSD")
    }

    // MARK: - Scores

    @Test func scoresFromHomePerspective() {
        let game = Self.makeGame(
            homeTeamScore: 3, awayTeamScore: 1,
            myTeamId: Self.myTeamUUID
        )
        #expect(game.ourScore == 3)
        #expect(game.theirScore == 1)
    }

    @Test func scoresFromAwayPerspective() {
        let game = Self.makeGame(
            homeTeamScore: 3, awayTeamScore: 1,
            myTeamId: Self.opponentUUID
        )
        #expect(game.ourScore == 1)
        #expect(game.theirScore == 3)
    }

    @Test func scoresAreNilPreGame() {
        let game = Self.makeGame()
        #expect(game.ourScore == nil)
        #expect(game.theirScore == nil)
    }

    // MARK: - Hashable

    @Test func equalityByIdOnly() {
        var game1 = Self.makeGame()
        var game2 = game1
        game1.myTeamId = Self.myTeamUUID
        game2.myTeamId = Self.opponentUUID
        #expect(game1 == game2)
    }
}

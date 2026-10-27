import Testing
import Foundation
@testable import ucsdmcs

/// Tests that simulate Supabase JSON responses to verify CodingKeys
/// match the actual API shape. These catch aliased join mismatches,
/// snake_case mapping errors, and missing/extra fields.
struct JSONDecodingTests {

    // MARK: - Shared decoder (matches DataService's game decoder)

    static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }

    // MARK: - Event

    @Test func decodeEventFromSupabaseJSON() throws {
        let json = """
        {
            "id": "aaaaaaaa-0000-0000-0000-000000000001",
            "season_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "team_id": "cccccccc-0000-0000-0000-000000000001",
            "event_type": "game",
            "event_date": "2026-11-15T18:00:00+00:00"
        }
        """
        let event = try Self.decoder.decode(Event.self, from: Data(json.utf8))
        #expect(event.eventType == "game")
        #expect(event.teamId == UUID(uuidString: "cccccccc-0000-0000-0000-000000000001"))
        #expect(event.seasonId == UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000001"))
    }

    // MARK: - Game (with aliased joins)

    @Test func decodeGameWithHomeAwayTeamJoins() throws {
        let json = """
        {
            "id": "11111111-0000-0000-0000-000000000001",
            "home_team_id": "aaaaaaaa-0000-0000-0000-000000000001",
            "away_team_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "home_team_score": 3,
            "away_team_score": 1,
            "is_neutral": false,
            "field_id": "cccccccc-0000-0000-0000-000000000001",
            "event_id": "dddddddd-0000-0000-0000-000000000001",
            "film_link": "https://film.example.com/game1",
            "tournament_id": null,
            "fields": {
                "id": "cccccccc-0000-0000-0000-000000000001",
                "name": "RIMAC Field",
                "area": "Campus",
                "maps_address": "9500 Gilman Dr, La Jolla",
                "picture_path": null,
                "recommended_parking": "Lot P704"
            },
            "home_team": {
                "id": "aaaaaaaa-0000-0000-0000-000000000001",
                "name": "UCSD MCS",
                "logo_path": "logos/ucsd.png",
                "data_alias": null,
                "team_code": null,
                "admin_code": null,
                "org_id": null,
                "sport_id": null,
                "division": "Men's A"
            },
            "away_team": {
                "id": "bbbbbbbb-0000-0000-0000-000000000001",
                "name": "UCLA BruinS",
                "logo_path": "logos/ucla.png",
                "data_alias": null,
                "team_code": null,
                "admin_code": null,
                "org_id": null,
                "sport_id": null,
                "division": null
            }
        }
        """
        let game = try Self.decoder.decode(Game.self, from: Data(json.utf8))

        #expect(game.homeTeamId == UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001"))
        #expect(game.awayTeamId == UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000001"))
        #expect(game.homeTeamScore == 3)
        #expect(game.awayTeamScore == 1)
        #expect(game.isNeutral == false)
        #expect(game.filmLink == "https://film.example.com/game1")
        #expect(game.tournamentId == nil)

        // Nested joins decoded
        #expect(game.fields?.name == "RIMAC Field")
        #expect(game.fields?.mapsAddress == "9500 Gilman Dr, La Jolla")
        #expect(game.homeTeam?.name == "UCSD MCS")
        #expect(game.homeTeam?.division == "Men's A")
        #expect(game.awayTeam?.name == "UCLA BruinS")
        #expect(game.awayTeam?.logoPath == "logos/ucla.png")
    }

    @Test func decodeGameWithNullJoins() throws {
        let json = """
        {
            "id": "11111111-0000-0000-0000-000000000001",
            "home_team_id": "aaaaaaaa-0000-0000-0000-000000000001",
            "away_team_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "home_team_score": null,
            "away_team_score": null,
            "is_neutral": null,
            "field_id": null,
            "event_id": null,
            "film_link": null,
            "tournament_id": null,
            "fields": null,
            "home_team": null,
            "away_team": null
        }
        """
        let game = try Self.decoder.decode(Game.self, from: Data(json.utf8))
        #expect(game.homeTeamScore == nil)
        #expect(game.awayTeamScore == nil)
        #expect(game.isNeutral == nil)
        #expect(game.fields == nil)
        #expect(game.homeTeam == nil)
        #expect(game.awayTeam == nil)
    }

    @Test func decodedGameComputedPropertiesFromHomePerspective() throws {
        let json = """
        {
            "id": "11111111-0000-0000-0000-000000000001",
            "home_team_id": "aaaaaaaa-0000-0000-0000-000000000001",
            "away_team_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "home_team_score": 5,
            "away_team_score": 2,
            "is_neutral": false,
            "field_id": null,
            "event_id": null,
            "film_link": null,
            "tournament_id": null,
            "fields": null,
            "home_team": {
                "id": "aaaaaaaa-0000-0000-0000-000000000001",
                "name": "UCSD", "logo_path": null, "data_alias": null,
                "team_code": null, "admin_code": null,
                "org_id": null, "sport_id": null, "division": null
            },
            "away_team": {
                "id": "bbbbbbbb-0000-0000-0000-000000000001",
                "name": "UCLA", "logo_path": null, "data_alias": null,
                "team_code": null, "admin_code": null,
                "org_id": null, "sport_id": null, "division": null
            }
        }
        """
        var game = try Self.decoder.decode(Game.self, from: Data(json.utf8))
        game.myTeamId = UUID(uuidString: "aaaaaaaa-0000-0000-0000-000000000001")!

        #expect(game.isHome == true)
        #expect(game.opponentName == "UCLA")
        #expect(game.title == "vs. UCLA")
        #expect(game.ourScore == 5)
        #expect(game.theirScore == 2)
    }

    @Test func decodedGameComputedPropertiesFromAwayPerspective() throws {
        let json = """
        {
            "id": "11111111-0000-0000-0000-000000000001",
            "home_team_id": "aaaaaaaa-0000-0000-0000-000000000001",
            "away_team_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "home_team_score": 5,
            "away_team_score": 2,
            "is_neutral": false,
            "field_id": null,
            "event_id": null,
            "film_link": null,
            "tournament_id": null,
            "fields": null,
            "home_team": {
                "id": "aaaaaaaa-0000-0000-0000-000000000001",
                "name": "UCSD", "logo_path": null, "data_alias": null,
                "team_code": null, "admin_code": null,
                "org_id": null, "sport_id": null, "division": null
            },
            "away_team": {
                "id": "bbbbbbbb-0000-0000-0000-000000000001",
                "name": "UCLA", "logo_path": null, "data_alias": null,
                "team_code": null, "admin_code": null,
                "org_id": null, "sport_id": null, "division": null
            }
        }
        """
        var game = try Self.decoder.decode(Game.self, from: Data(json.utf8))
        game.myTeamId = UUID(uuidString: "bbbbbbbb-0000-0000-0000-000000000001")!

        #expect(game.isHome == false)
        #expect(game.opponentName == "UCSD")
        #expect(game.title == "@ UCSD")
        #expect(game.ourScore == 2)
        #expect(game.theirScore == 5)
    }

    // MARK: - RosterEntry (with nested people join)

    @Test func decodeRosterEntryWithPerson() throws {
        let json = """
        {
            "id": "aaaaaaaa-0000-0000-0000-000000000001",
            "person_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "season_id": "cccccccc-0000-0000-0000-000000000001",
            "team_id": "dddddddd-0000-0000-0000-000000000001",
            "class": "Senior",
            "position": "Handler",
            "number": 7,
            "people": {
                "id": "bbbbbbbb-0000-0000-0000-000000000001",
                "name": "John Doe",
                "hometown": "San Diego",
                "picture_path": null,
                "phone": "555-1234"
            }
        }
        """
        let entry = try JSONDecoder().decode(RosterEntry.self, from: Data(json.utf8))
        #expect(entry.teamId == UUID(uuidString: "dddddddd-0000-0000-0000-000000000001"))
        #expect(entry.playerClass == "Senior")
        #expect(entry.number == 7)
        #expect(entry.displayName == "John Doe")
        #expect(entry.displayNumber == "#7")
    }

    // MARK: - Availability (with nested roster + people joins)

    @Test func decodeAvailabilityWithNestedJoins() throws {
        let json = """
        {
            "id": "aaaaaaaa-0000-0000-0000-000000000001",
            "event_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "roster_id": "cccccccc-0000-0000-0000-000000000001",
            "status": "yes",
            "updated_at": "2026-10-25T12:00:00+00:00",
            "roster": {
                "id": "cccccccc-0000-0000-0000-000000000001",
                "person_id": "dddddddd-0000-0000-0000-000000000001",
                "season_id": "eeeeeeee-0000-0000-0000-000000000001",
                "team_id": "ffffffff-0000-0000-0000-000000000001",
                "class": "Junior",
                "position": "Cutter",
                "number": 23,
                "people": {
                    "id": "dddddddd-0000-0000-0000-000000000001",
                    "name": "Jane Smith",
                    "hometown": null,
                    "picture_path": null,
                    "phone": null
                }
            }
        }
        """
        let decoder = Self.decoder
        let avail = try decoder.decode(Availability.self, from: Data(json.utf8))
        #expect(avail.status == .yes)
        #expect(avail.roster?.displayName == "Jane Smith")
        #expect(avail.roster?.number == 23)
        #expect(avail.roster?.teamId == UUID(uuidString: "ffffffff-0000-0000-0000-000000000001"))
    }

    // MARK: - Practice (with nested field join)

    @Test func decodePracticeWithField() throws {
        let json = """
        {
            "id": "aaaaaaaa-0000-0000-0000-000000000001",
            "event_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "field_id": "cccccccc-0000-0000-0000-000000000001",
            "notes": "Bring cleats",
            "film_link": null,
            "fields": {
                "id": "cccccccc-0000-0000-0000-000000000001",
                "name": "Warren Field",
                "area": "Campus",
                "maps_address": "9500 Gilman Dr",
                "picture_path": null,
                "recommended_parking": "Lot P704"
            }
        }
        """
        let practice = try JSONDecoder().decode(Practice.self, from: Data(json.utf8))
        #expect(practice.notes == "Bring cleats")
        #expect(practice.fields?.name == "Warren Field")
        #expect(practice.fields?.recommendedParking == "Lot P704")
    }

    // MARK: - Tournament (with nested field join)

    @Test func decodeTournamentWithField() throws {
        let json = """
        {
            "id": "aaaaaaaa-0000-0000-0000-000000000001",
            "event_id": "bbbbbbbb-0000-0000-0000-000000000001",
            "name": "Southwest Regionals",
            "website_link": "https://usau.org/regionals",
            "location": "Tucson, AZ",
            "field_id": "cccccccc-0000-0000-0000-000000000001",
            "fields": {
                "id": "cccccccc-0000-0000-0000-000000000001",
                "name": "Kino Sports Complex",
                "area": "Tucson",
                "maps_address": "2500 E Ajo Way",
                "picture_path": null,
                "recommended_parking": null
            }
        }
        """
        let tournament = try JSONDecoder().decode(Tournament.self, from: Data(json.utf8))
        #expect(tournament.name == "Southwest Regionals")
        #expect(tournament.websiteLink == "https://usau.org/regionals")
        #expect(tournament.location == "Tucson, AZ")
        #expect(tournament.fields?.name == "Kino Sports Complex")
    }

    // MARK: - Season

    @Test func decodeSeason() throws {
        let json = """
        {
            "id": "aaaaaaaa-0000-0000-0000-000000000001",
            "year": 2026,
            "is_current": true
        }
        """
        let season = try JSONDecoder().decode(Season.self, from: Data(json.utf8))
        #expect(season.year == 2026)
        #expect(season.isCurrent == true)
    }

    // MARK: - SocialEvent

    @Test func decodeSocialEvent() throws {
        let json = """
        {
            "id": "aaaaaaaa-0000-0000-0000-000000000001",
            "name": "Team BBQ",
            "description": "End of season celebration",
            "event_id": "bbbbbbbb-0000-0000-0000-000000000001"
        }
        """
        let social = try JSONDecoder().decode(SocialEvent.self, from: Data(json.utf8))
        #expect(social.name == "Team BBQ")
        #expect(social.description == "End of season celebration")
    }
}

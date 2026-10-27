import Testing
import Foundation
@testable import ucsdmcs

struct RosterEntryTests {

    static let person = Person(
        id: UUID(), name: "John Doe", hometown: "San Diego",
        picturePath: nil, phone: "555-1234"
    )

    static func makeEntry(
        number: Int? = 7,
        people: Person? = person
    ) -> RosterEntry {
        RosterEntry(
            id: UUID(), personId: people?.id ?? UUID(),
            seasonId: UUID(), teamId: UUID(),
            playerClass: "Senior", position: "Handler",
            number: number, people: people
        )
    }

    // MARK: - displayName

    @Test func displayNameFromPerson() {
        let entry = Self.makeEntry()
        #expect(entry.displayName == "John Doe")
    }

    @Test func displayNameFallbackWhenNoPerson() {
        let entry = Self.makeEntry(people: nil)
        #expect(entry.displayName == "Unknown")
    }

    // MARK: - displayNumber

    @Test func displayNumberFormatted() {
        let entry = Self.makeEntry(number: 7)
        #expect(entry.displayNumber == "#7")
    }

    @Test func displayNumberNilWhenNoNumber() {
        let entry = Self.makeEntry(number: nil)
        #expect(entry.displayNumber == nil)
    }
}

struct TeamTests {

    @Test func teamDecodesAllFields() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "name": "UCSD MCS",
            "logo_path": "logos/ucsd.png",
            "data_alias": "ucsd-mcs",
            "team_code": "ABC123",
            "admin_code": "ADMIN1",
            "org_id": "00000000-0000-0000-0000-000000000002",
            "sport_id": "00000000-0000-0000-0000-000000000003",
            "division": "Men's A"
        }
        """
        let team = try JSONDecoder().decode(Team.self, from: Data(json.utf8))
        #expect(team.name == "UCSD MCS")
        #expect(team.logoPath == "logos/ucsd.png")
        #expect(team.division == "Men's A")
        #expect(team.orgId != nil)
        #expect(team.sportId != nil)
    }

    @Test func teamDecodesWithNullOptionals() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "name": "Pickup Team",
            "logo_path": null,
            "data_alias": null,
            "team_code": null,
            "admin_code": null,
            "org_id": null,
            "sport_id": null,
            "division": null
        }
        """
        let team = try JSONDecoder().decode(Team.self, from: Data(json.utf8))
        #expect(team.name == "Pickup Team")
        #expect(team.logoPath == nil)
        #expect(team.orgId == nil)
        #expect(team.sportId == nil)
        #expect(team.division == nil)
    }
}

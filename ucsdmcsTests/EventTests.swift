import Testing
import Foundation
@testable import ucsdmcs

struct EventTests {

    static func makeEvent(eventType: String = "practice") -> Event {
        Event(
            id: UUID(), seasonId: UUID(), teamId: UUID(),
            eventType: eventType, eventDate: Date()
        )
    }

    // MARK: - typeLabel

    @Test func typeLabelPractice() {
        #expect(Self.makeEvent(eventType: "practice").typeLabel == "Practice")
    }

    @Test func typeLabelGame() {
        #expect(Self.makeEvent(eventType: "game").typeLabel == "Game")
    }

    @Test func typeLabelSocial() {
        #expect(Self.makeEvent(eventType: "social").typeLabel == "Social")
    }

    @Test func typeLabelTournament() {
        #expect(Self.makeEvent(eventType: "tournament").typeLabel == "Tournament")
    }

    @Test func typeLabelUnknownCapitalizes() {
        #expect(Self.makeEvent(eventType: "scrimmage").typeLabel == "Scrimmage")
    }

    // MARK: - typeIcon

    @Test func typeIconPractice() {
        #expect(Self.makeEvent(eventType: "practice").typeIcon == "figure.run")
    }

    @Test func typeIconGame() {
        #expect(Self.makeEvent(eventType: "game").typeIcon == "sportscourt.fill")
    }

    @Test func typeIconSocial() {
        #expect(Self.makeEvent(eventType: "social").typeIcon == "party.popper.fill")
    }

    @Test func typeIconTournament() {
        #expect(Self.makeEvent(eventType: "tournament").typeIcon == "trophy.fill")
    }

    @Test func typeIconUnknownFallback() {
        #expect(Self.makeEvent(eventType: "other").typeIcon == "calendar")
    }
}

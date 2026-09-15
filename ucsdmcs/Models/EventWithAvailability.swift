import Foundation

struct EventWithAvailability: Identifiable {
    let event: Event
    let responses: [Availability]
    let currentRosterStatus: AvailabilityStatus?

    // Subtype detail (only one will be non-nil)
    var practice: Practice?
    var game: Game?
    var socialEvent: SocialEvent?
    var tournament: Tournament?

    var id: UUID { event.id }

    var yesCount: Int { responses.filter { $0.status == .yes }.count }
    var noCount: Int { responses.filter { $0.status == .no }.count }
    var totalResponded: Int { responses.count }

    var title: String {
        switch event.eventType {
        case "practice": return "Practice"
        case "game": return game?.title ?? "Game"
        case "social": return socialEvent?.name ?? "Social Event"
        case "tournament": return tournament?.name ?? "Tournament"
        default: return event.typeLabel
        }
    }

    var location: String? {
        switch event.eventType {
        case "practice": return practice?.fields?.name
        case "game": return game?.fields?.name
        case "tournament": return tournament?.location ?? tournament?.fields?.name
        default: return nil
        }
    }

    var mapsAddress: String? {
        switch event.eventType {
        case "practice": return practice?.fields?.mapsAddress
        case "game": return game?.fields?.mapsAddress
        case "tournament": return tournament?.fields?.mapsAddress
        default: return nil
        }
    }

    var opponentLogoURL: URL? {
        guard event.eventType == "game",
              let logoPath = game?.teams?.logoPath else { return nil }
        return SupabaseConfig.storageURL(for: logoPath)
    }

    var notes: String? {
        switch event.eventType {
        case "practice": return practice?.notes
        case "game": return game?.filmLink != nil ? "Film available" : nil
        case "tournament": return tournament?.websiteLink != nil ? "Website available" : nil
        default: return nil
        }
    }
}

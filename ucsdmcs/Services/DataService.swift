import Foundation
import Supabase

@Observable
final class DataService {

    var teams: [Team] = []
    var currentSeason: Season?
    var roster: [RosterEntry] = []
    var events: [Event] = []
    var availabilityByEvent: [UUID: [Availability]] = [:]

    // Subtype caches
    var practices: [UUID: Practice] = [:]   // keyed by event_id
    var games: [UUID: Game] = [:]           // keyed by event_id
    var socialEvents: [UUID: SocialEvent] = [:]
    var tournaments: [UUID: Tournament] = [:]

    var isLoading = false
    var hasLoadedSchedule = false
    var errorMessage: String?

    private var supabase: SupabaseClient { SupabaseConfig.client }

    // MARK: - Teams

    func fetchTeams() async {
        do {
            teams = try await supabase
                .from("teams")
                .select()
                .execute()
                .value
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Season

    func fetchCurrentSeason() async {
        do {
            let seasons: [Season] = try await supabase
                .from("seasons")
                .select()
                .eq("is_current", value: true)
                .execute()
                .value
            currentSeason = seasons.first
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Roster

    func fetchRoster(seasonId: UUID) async {
        do {
            roster = try await supabase
                .from("roster")
                .select("*, people(*)")
                .eq("season_id", value: seasonId.uuidString)
                .execute()
                .value

            // Sort by number, then name
            roster.sort {
                if let a = $0.number, let b = $1.number { return a < b }
                if $0.number != nil { return true }
                if $1.number != nil { return false }
                return $0.displayName < $1.displayName
            }
        } catch {
            print("fetchRoster error: \(error)")
            errorMessage = "Roster: \(error.localizedDescription)"
        }
    }

    // MARK: - Events

    func fetchUpcomingEvents(seasonId: UUID) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let now = ISO8601DateFormatter().string(from: Date())
            events = try await supabase
                .from("events")
                .select()
                .eq("season_id", value: seasonId.uuidString)
                .gte("event_date", value: now)
                .order("event_date")
                .execute()
                .value

            // Fetch subtype details for all events in parallel
            await withTaskGroup(of: Void.self) { group in
                for event in events {
                    group.addTask { await self.fetchEventSubtype(event) }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func fetchEventSubtype(_ event: Event) async {
        do {
            switch event.eventType {
            case "practice":
                let results: [Practice] = try await supabase
                    .from("practices")
                    .select("*, fields(*)")
                    .eq("event_id", value: event.id.uuidString)
                    .execute()
                    .value
                if let practice = results.first {
                    practices[event.id] = practice
                }

            case "game":
                let response = try await supabase
                    .from("games")
                    .select("*, fields(*), teams!games_opponent_id_fkey(*)")
                    .eq("event_id", value: event.id.uuidString)
                    .execute()
                if let raw = String(data: response.data, encoding: .utf8) {
                    print("GAME RAW JSON: \(raw)")
                }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let results: [Game] = try decoder.decode([Game].self, from: response.data)
                if let game = results.first {
                    print("GAME DECODED: opponent=\(game.opponentName) logoPath=\(game.teams?.logoPath ?? "nil")")
                    games[event.id] = game
                }

            case "social":
                let results: [SocialEvent] = try await supabase
                    .from("social_events")
                    .select()
                    .eq("event_id", value: event.id.uuidString)
                    .execute()
                    .value
                if let social = results.first {
                    socialEvents[event.id] = social
                }

            case "tournament":
                let results: [Tournament] = try await supabase
                    .from("tournaments")
                    .select("*, fields(*)")
                    .eq("event_id", value: event.id.uuidString)
                    .execute()
                    .value
                if let tournament = results.first {
                    tournaments[event.id] = tournament
                }

            default:
                break
            }
        } catch {
            print("Failed to fetch subtype for event \(event.id): \(error)")
        }
    }

    // MARK: - Availability

    func fetchAvailability(eventId: UUID) async {
        do {
            let results: [Availability] = try await supabase
                .from("availability")
                .select("*, roster(*, people(*))")
                .eq("event_id", value: eventId.uuidString)
                .execute()
                .value
            availabilityByEvent[eventId] = results
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchAllAvailability(for eventIds: [UUID]) async {
        await withTaskGroup(of: Void.self) { group in
            for eventId in eventIds {
                group.addTask { await self.fetchAvailability(eventId: eventId) }
            }
        }
    }

    func setAvailability(eventId: UUID, rosterId: UUID, status: AvailabilityStatus) async {
        do {
            let payload: [String: String] = [
                "event_id": eventId.uuidString,
                "roster_id": rosterId.uuidString,
                "status": status.rawValue
            ]
            try await supabase
                .from("availability")
                .upsert(payload, onConflict: "event_id,roster_id")
                .execute()

            // Refresh this event's availability
            await fetchAvailability(eventId: eventId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Composite Helpers

    func eventsWithAvailability(currentRosterId: UUID) -> [EventWithAvailability] {
        events.map { event in
            let responses = availabilityByEvent[event.id] ?? []
            let myStatus = responses.first { $0.rosterId == currentRosterId }?.status
            var item = EventWithAvailability(
                event: event,
                responses: responses,
                currentRosterStatus: myStatus
            )
            item.practice = practices[event.id]
            item.game = games[event.id]
            item.socialEvent = socialEvents[event.id]
            item.tournament = tournaments[event.id]
            return item
        }
    }

    func rosterWithoutResponse(eventId: UUID) -> [RosterEntry] {
        let respondedIds = Set((availabilityByEvent[eventId] ?? []).map(\.rosterId))
        return roster.filter { !respondedIds.contains($0.id) }
    }
}

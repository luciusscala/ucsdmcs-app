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

    func fetchTeamByCode(_ code: String) async -> Team? {
        do {
            let results: [Team] = try await supabase
                .from("teams")
                .select()
                .eq("team_code", value: code)
                .execute()
                .value
            return results.first
        } catch {
            errorMessage = error.localizedDescription
            return nil
        }
    }

    func updatePhone(personId: UUID, phone: String) async {
        do {
            try await supabase
                .from("people")
                .update(["phone": phone])
                .eq("id", value: personId.uuidString)
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateHometown(personId: UUID, hometown: String) async {
        do {
            try await supabase
                .from("people")
                .update(["hometown": hometown])
                .eq("id", value: personId.uuidString)
                .execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func validateAdminCode(teamId: UUID, code: String) async -> Bool {
        do {
            print(teamId)
            let results: [Team] = try await supabase
                .from("teams")
                .select("*")
                .eq("id", value: teamId.uuidString)
                .execute()
                .value
            
            return results.first?.adminCode == code
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - Fields

    var fields: [Field] = []

    func fetchFields() async {
        do {
            fields = try await supabase
                .from("fields")
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
        let isInitialLoad = events.isEmpty
        if isInitialLoad { isLoading = true }
        defer { if isInitialLoad { isLoading = false } }

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
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let results: [Game] = try decoder.decode([Game].self, from: response.data)
                if let game = results.first {
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
        // Optimistic update: immediately reflect in local state
        if var existing = availabilityByEvent[eventId] {
            if let idx = existing.firstIndex(where: { $0.rosterId == rosterId }) {
                let old = existing[idx]
                existing[idx] = Availability(
                    id: old.id,
                    eventId: old.eventId,
                    rosterId: old.rosterId,
                    status: status,
                    updatedAt: old.updatedAt,
                    roster: old.roster
                )
            } else {
                existing.append(Availability(
                    id: UUID(),
                    eventId: eventId,
                    rosterId: rosterId,
                    status: status,
                    updatedAt: nil,
                    roster: roster.first { $0.id == rosterId }
                ))
            }
            availabilityByEvent[eventId] = existing
        } else {
            availabilityByEvent[eventId] = [Availability(
                id: UUID(),
                eventId: eventId,
                rosterId: rosterId,
                status: status,
                updatedAt: nil,
                roster: roster.first { $0.id == rosterId }
            )]
        }

        // Sync with server
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

            // Refresh to get server-assigned ID and updated_at
            await fetchAvailability(eventId: eventId)
        } catch {
            // Revert on failure
            await fetchAvailability(eventId: eventId)
            errorMessage = error.localizedDescription
        }
    }

    func deleteAvailability(eventId: UUID, rosterId: UUID) async {
        // Optimistic update: remove from local state
        if var existing = availabilityByEvent[eventId] {
            existing.removeAll { $0.rosterId == rosterId }
            availabilityByEvent[eventId] = existing
        }

        // Sync with server
        do {
            try await supabase
                .from("availability")
                .delete()
                .eq("event_id", value: eventId.uuidString)
                .eq("roster_id", value: rosterId.uuidString)
                .execute()

            await fetchAvailability(eventId: eventId)
        } catch {
            await fetchAvailability(eventId: eventId)
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

    // MARK: - Admin: Create Events

    func createPractice(seasonId: UUID, date: Date, fieldId: UUID, notes: String?) async {
        do {
            let eventPayload: [String: String] = [
                "season_id": seasonId.uuidString,
                "event_type": "practice",
                "event_date": ISO8601DateFormatter().string(from: date)
            ]
            let eventResult: [Event] = try await supabase
                .from("events")
                .insert(eventPayload)
                .select()
                .execute()
                .value

            guard let newEvent = eventResult.first else { return }

            var practicePayload: [String: String] = [
                "event_id": newEvent.id.uuidString,
                "field_id": fieldId.uuidString
            ]
            if let notes, !notes.isEmpty {
                practicePayload["notes"] = notes
            }
            try await supabase
                .from("practices")
                .insert(practicePayload)
                .execute()

            // Refresh schedule
            hasLoadedSchedule = false
            await fetchUpcomingEvents(seasonId: seasonId)
            await fetchAllAvailability(for: events.map(\.id))
            hasLoadedSchedule = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createRepeatingPractices(seasonId: UUID, days: Set<Int>, startDate: Date, endDate: Date, time: Date, fieldId: UUID, notes: String?) async {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

        var currentDate = startDate
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            if days.contains(weekday) {
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)
                dateComponents.hour = timeComponents.hour
                dateComponents.minute = timeComponents.minute
                if let practiceDate = calendar.date(from: dateComponents) {
                    await createPractice(seasonId: seasonId, date: practiceDate, fieldId: fieldId, notes: notes)
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            // Safety: break if stuck
            if currentDate > endDate.addingTimeInterval(86400) { break }
        }
    }

    func createGame(seasonId: UUID, date: Date, opponentId: UUID, fieldId: UUID, isHome: Bool) async {
        do {
            let eventPayload: [String: String] = [
                "season_id": seasonId.uuidString,
                "event_type": "game",
                "event_date": ISO8601DateFormatter().string(from: date)
            ]
            let eventResult: [Event] = try await supabase
                .from("events")
                .insert(eventPayload)
                .select()
                .execute()
                .value

            guard let newEvent = eventResult.first else { return }

            let gamePayload: [String: AnyJSON] = [
                "event_id": .string(newEvent.id.uuidString),
                "opponent_id": .string(opponentId.uuidString),
                "field_id": .string(fieldId.uuidString),
                "is_home": .bool(isHome)
            ]
            try await supabase
                .from("games")
                .insert(gamePayload)
                .execute()

            hasLoadedSchedule = false
            await fetchUpcomingEvents(seasonId: seasonId)
            await fetchAllAvailability(for: events.map(\.id))
            hasLoadedSchedule = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Admin: Update Events

    func updatePractice(eventId: UUID, date: Date, fieldId: UUID, notes: String?) async {
        do {
            try await supabase
                .from("events")
                .update(["event_date": ISO8601DateFormatter().string(from: date)])
                .eq("id", value: eventId.uuidString)
                .execute()

            var practiceUpdate: [String: String] = ["field_id": fieldId.uuidString]
            practiceUpdate["notes"] = notes ?? ""
            try await supabase
                .from("practices")
                .update(practiceUpdate)
                .eq("event_id", value: eventId.uuidString)
                .execute()

            if let seasonId = currentSeason?.id {
                hasLoadedSchedule = false
                await fetchUpcomingEvents(seasonId: seasonId)
                await fetchAllAvailability(for: events.map(\.id))
                hasLoadedSchedule = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateGame(eventId: UUID, date: Date, opponentId: UUID, fieldId: UUID, isHome: Bool) async {
        do {
            try await supabase
                .from("events")
                .update(["event_date": ISO8601DateFormatter().string(from: date)])
                .eq("id", value: eventId.uuidString)
                .execute()

            let gameUpdate: [String: AnyJSON] = [
                "opponent_id": .string(opponentId.uuidString),
                "field_id": .string(fieldId.uuidString),
                "is_home": .bool(isHome)
            ]
            try await supabase
                .from("games")
                .update(gameUpdate)
                .eq("event_id", value: eventId.uuidString)
                .execute()

            if let seasonId = currentSeason?.id {
                hasLoadedSchedule = false
                await fetchUpcomingEvents(seasonId: seasonId)
                await fetchAllAvailability(for: events.map(\.id))
                hasLoadedSchedule = true
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Admin: Delete Events

    func deleteEvent(eventId: UUID, eventType: String) async {
        do {
            // Delete subtype first (FK constraint)
            let subtypeTable: String
            switch eventType {
            case "practice": subtypeTable = "practices"
            case "game": subtypeTable = "games"
            case "social": subtypeTable = "social_events"
            case "tournament": subtypeTable = "tournaments"
            default: subtypeTable = ""
            }

            if !subtypeTable.isEmpty {
                try await supabase
                    .from(subtypeTable)
                    .delete()
                    .eq("event_id", value: eventId.uuidString)
                    .execute()
            }

            // Delete availability
            try await supabase
                .from("availability")
                .delete()
                .eq("event_id", value: eventId.uuidString)
                .execute()

            // Delete event
            try await supabase
                .from("events")
                .delete()
                .eq("id", value: eventId.uuidString)
                .execute()

            // Remove from local state
            events.removeAll { $0.id == eventId }
            practices.removeValue(forKey: eventId)
            games.removeValue(forKey: eventId)
            socialEvents.removeValue(forKey: eventId)
            tournaments.removeValue(forKey: eventId)
            availabilityByEvent.removeValue(forKey: eventId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Bulk Actions

    func bulkSetAvailability(eventIds: [UUID], rosterId: UUID, status: AvailabilityStatus) async {
        // Upsert all in parallel (skip per-event refetch)
        await withTaskGroup(of: Void.self) { group in
            for eventId in eventIds {
                group.addTask {
                    let payload: [String: String] = [
                        "event_id": eventId.uuidString,
                        "roster_id": rosterId.uuidString,
                        "status": status.rawValue
                    ]
                    try? await self.supabase
                        .from("availability")
                        .upsert(payload, onConflict: "event_id,roster_id")
                        .execute()
                }
            }
        }
        // Single bulk refresh at the end
        await fetchAllAvailability(for: eventIds)
    }

    func bulkDeleteEvents(eventIds: [UUID]) async {
        for eventId in eventIds {
            if let event = events.first(where: { $0.id == eventId }) {
                await deleteEvent(eventId: eventId, eventType: event.eventType)
            }
        }
    }
}

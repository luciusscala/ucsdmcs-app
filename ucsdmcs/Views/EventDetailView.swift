import SwiftUI

struct EventDetailView: View {
    let eventID: UUID
    let rosterID: UUID
    @Environment(DataService.self) private var dataService
    @Environment(\.openURL) private var openURL

    private var event: Event? {
        dataService.events.first { $0.id == eventID }
    }

    private var responses: [Availability] {
        dataService.availabilityByEvent[eventID] ?? []
    }

    private var myStatus: AvailabilityStatus? {
        responses.first { $0.rosterId == rosterID }?.status
    }

    private var noResponseRoster: [RosterEntry] {
        dataService.rosterWithoutResponse(eventId: eventID)
    }

    var body: some View {
        ScrollView {
            if let event {
                VStack(spacing: 24) {
                    eventInfoCard(event)
                    availabilityPickerSection(event)
                    rosterBreakdown
                }
                .padding()
            } else {
                ProgressView()
            }
        }
        .navigationTitle(event?.typeLabel ?? "Event")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await dataService.fetchAvailability(eventId: eventID)
        }
    }

    // MARK: - Event Info Card

    private func eventInfoCard(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Game: show opponent with logo
            if event.eventType == "game", let game = dataService.games[event.id] {
                HStack(spacing: 10) {
                    if let logoPath = game.teams?.logoPath,
                       let logoURL = SupabaseConfig.storageURL(for: logoPath) {
                        AsyncImage(url: logoURL) { image in
                            image.resizable().scaledToFit()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(.rect(cornerRadius: 8))
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(game.title)
                            .font(.title3.weight(.semibold))
                        Text(game.isHome ? "Home" : "Away")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            } else {
                Text(event.typeLabel)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(typeColor(for: event.eventType))
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text(event.eventDate.formatted(.dateTime.weekday(.wide).month().day()))
                    .font(.body)

                Text(event.eventDate.formatted(.dateTime.hour().minute()))
                    .font(.body)
                    .foregroundStyle(.secondary)

                // Location — tappable to open Google Maps
                if let locationName = subtypeLocation(for: event) {
                    if let address = subtypeMapsAddress(for: event),
                       let encoded = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                       let mapsURL = URL(string: "https://maps.google.com/?q=\(encoded)") {
                        Button {
                            openURL(mapsURL)
                        } label: {
                            HStack(spacing: 4) {
                                Text(locationName)
                                    .font(.body)
                                Image(systemName: "arrow.up.right.square")
                                    .font(.caption)
                            }
                            .foregroundStyle(.blue)
                        }
                    } else {
                        Text(locationName)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Notes
            if let notes = subtypeNotes(for: event) {
                Divider()
                Text(notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.fill.tertiary, in: .rect(cornerRadius: 12))
    }

    // MARK: - Availability Picker

    private func availabilityPickerSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Availability")
                .font(.headline)
            AvailabilityPicker(selected: myStatus) { newStatus in
                Task {
                    await dataService.setAvailability(
                        eventId: event.id,
                        rosterId: rosterID,
                        status: newStatus
                    )
                }
            }
        }
    }

    // MARK: - Roster Breakdown

    private var rosterBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Team Responses")
                .font(.headline)

            ForEach(AvailabilityStatus.allCases, id: \.self) { status in
                let filtered = responses.filter { $0.status == status }
                if !filtered.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            AvailabilityBadge(status: status)
                            Text("(\(filtered.count))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        VStack(spacing: 0) {
                            ForEach(filtered) { avail in
                                HStack {
                                    if let num = avail.roster?.number {
                                        Text("#\(num)")
                                            .font(.subheadline.monospaced().weight(.semibold))
                                            .foregroundStyle(.secondary)
                                            .frame(width: 36, alignment: .trailing)
                                    }
                                    Text(avail.roster?.displayName ?? "Unknown")
                                        .font(.body)
                                    Spacer()
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                if avail.id != filtered.last?.id {
                                    Divider()
                                        .padding(.leading, 12)
                                }
                            }
                        }
                        .background(.fill.tertiary, in: .rect(cornerRadius: 10))
                    }
                }
            }

            if !noResponseRoster.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("No Response")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                        Text("(\(noResponseRoster.count))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 0) {
                        ForEach(noResponseRoster) { entry in
                            HStack {
                                if let num = entry.number {
                                    Text("#\(num)")
                                        .font(.subheadline.monospaced().weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 36, alignment: .trailing)
                                }
                                Text(entry.displayName)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            if entry.id != noResponseRoster.last?.id {
                                Divider()
                                    .padding(.leading, 12)
                            }
                        }
                    }
                    .background(.fill.tertiary, in: .rect(cornerRadius: 10))
                }
            }
        }
    }

    // MARK: - Helpers

    private func typeColor(for eventType: String) -> Color {
        switch eventType {
        case "game": return .orange
        case "practice": return .blue
        case "social": return .purple
        case "tournament": return .yellow
        default: return .gray
        }
    }

    private func subtypeLocation(for event: Event) -> String? {
        switch event.eventType {
        case "practice": return dataService.practices[event.id]?.fields?.name
        case "game": return dataService.games[event.id]?.fields?.name
        case "tournament": return dataService.tournaments[event.id]?.location ?? dataService.tournaments[event.id]?.fields?.name
        default: return nil
        }
    }

    private func subtypeMapsAddress(for event: Event) -> String? {
        switch event.eventType {
        case "practice": return dataService.practices[event.id]?.fields?.mapsAddress
        case "game": return dataService.games[event.id]?.fields?.mapsAddress
        case "tournament": return dataService.tournaments[event.id]?.fields?.mapsAddress
        default: return nil
        }
    }

    private func subtypeNotes(for event: Event) -> String? {
        switch event.eventType {
        case "practice": return dataService.practices[event.id]?.notes
        default: return nil
        }
    }
}

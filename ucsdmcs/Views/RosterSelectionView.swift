import SwiftUI

struct RosterSelectionView: View {
    @Environment(DataService.self) private var dataService
    @AppStorage("teamID") private var savedTeamID: String = ""
    @AppStorage("rosterID") private var savedRosterID: String = ""

    private var groupedRoster: [(position: String, entries: [RosterEntry])] {
        let grouped = Dictionary(grouping: dataService.roster) { $0.position }
        let order = ["GK", "DEF", "MID", "FWD", "ATT"]
        return grouped
            .sorted { a, b in
                let ai = order.firstIndex(of: a.key) ?? order.count
                let bi = order.firstIndex(of: b.key) ?? order.count
                return ai == bi ? a.key < b.key : ai < bi
            }
            .map { (position: $0.key, entries: $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if dataService.roster.isEmpty && dataService.currentSeason == nil {
                    ProgressView("Loading roster...")
                } else if dataService.roster.isEmpty {
                    EmptyStateView(
                        icon: "person.3",
                        title: "No Roster Found",
                        subtitle: "No players found for the current season."
                    )
                } else {
                    List {
                        Section {
                            Text("Select your name from the roster")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .listRowBackground(Color.clear)
                        }

                        ForEach(groupedRoster, id: \.position) { group in
                            Section(group.position) {
                                ForEach(group.entries) { entry in
                                    Button {
                                        savedRosterID = entry.id.uuidString
                                    } label: {
                                        HStack {
                                            if let num = entry.number {
                                                Text("#\(num)")
                                                    .font(.subheadline.monospaced().weight(.semibold))
                                                    .foregroundStyle(.secondary)
                                                    .frame(width: 36, alignment: .trailing)
                                            }
                                            Text(entry.displayName)
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                            Text(entry.playerClass)
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                            }
                        }

                        Section {
                            Button("Not the right team?", role: .destructive) {
                                savedTeamID = ""
                                savedRosterID = ""
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .navigationTitle("Roster")
            .overlay {
                if let error = dataService.errorMessage {
                    VStack {
                        Spacer()
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding()
                            .background(.ultraThinMaterial, in: .rect(cornerRadius: 8))
                            .padding()
                    }
                }
            }
            .task {
                await dataService.fetchCurrentSeason()
                if let season = dataService.currentSeason {
                    await dataService.fetchRoster(seasonId: season.id)
                } else {
                    dataService.errorMessage = "No current season found. Make sure a season has is_current = true."
                }
            }
        }
    }
}

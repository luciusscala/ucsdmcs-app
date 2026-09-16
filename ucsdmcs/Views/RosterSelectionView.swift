import SwiftUI

struct RosterSelectionView: View {
    @Environment(DataService.self) private var dataService
    @AppStorage("teamID") private var savedTeamID: String = ""
    @AppStorage("rosterID") private var savedRosterID: String = ""

    private var sortedRoster: [RosterEntry] {
        dataService.roster.sorted { $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending }
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
                            ForEach(sortedRoster) { entry in
                                Button {
                                    savedRosterID = entry.id.uuidString
                                } label: {
                                    HStack {
                                        Text(entry.displayName)
                                            .font(.body)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
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
            .navigationTitle("Select Your Name")
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
                dataService.errorMessage = nil
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

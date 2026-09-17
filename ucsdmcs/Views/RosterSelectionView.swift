import SwiftUI

struct RosterSelectionView: View {
    @Environment(DataService.self) private var dataService
    @AppStorage("teamID") private var savedTeamID: String = ""
    @AppStorage("rosterID") private var savedRosterID: String = ""
    @State private var pendingEntry: RosterEntry?

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
                                    pendingEntry = entry
                                } label: {
                                    HStack {
                                        Text(entry.displayName)
                                            .font(.body)
                                            .foregroundStyle(.white)
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
            .alert("Is this you?", isPresented: Binding(
                get: { pendingEntry != nil },
                set: { if !$0 { pendingEntry = nil } }
            )) {
                Button("Yes, that's me") {
                    if let entry = pendingEntry {
                        savedRosterID = entry.id.uuidString
                    }
                    pendingEntry = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingEntry = nil
                }
            } message: {
                Text("You selected \(pendingEntry?.displayName ?? ""). Make sure this is your name.")
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

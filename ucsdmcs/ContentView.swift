import SwiftUI

struct ContentView: View {
    @AppStorage("teamID") private var savedTeamID: String = ""
    @AppStorage("rosterID") private var savedRosterID: String = ""
    @AppStorage("phoneEntered") private var phoneEntered: String = ""
    @Environment(DataService.self) private var dataService

    var body: some View {
        Group {
            if savedTeamID.isEmpty {
                TeamSelectionView()
            } else if savedRosterID.isEmpty {
                RosterSelectionView()
            } else if phoneEntered.isEmpty,
                      let rosterUUID = UUID(uuidString: savedRosterID) {
                PhoneNumberEntryView(
                    personId: personId(for: rosterUUID)
                )
                .task {
                    // Ensure roster is loaded so we can look up personId
                    if dataService.roster.isEmpty {
                        await dataService.fetchCurrentSeason()
                        if let season = dataService.currentSeason {
                            await dataService.fetchRoster(seasonId: season.id)
                        }
                    }
                }
            } else if let rosterUUID = UUID(uuidString: savedRosterID) {
                MainTabView(rosterID: rosterUUID)
            } else {
                TeamSelectionView()
                    .onAppear {
                        savedRosterID = ""
                        savedTeamID = ""
                        phoneEntered = ""
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: savedTeamID)
        .animation(.easeInOut(duration: 0.3), value: savedRosterID)
        .animation(.easeInOut(duration: 0.3), value: phoneEntered)
    }

    private func personId(for rosterUUID: UUID) -> UUID {
        dataService.roster.first { $0.id == rosterUUID }?.personId ?? UUID()
    }
}

struct MainTabView: View {
    let rosterID: UUID

    var body: some View {
        TabView {
            Tab("Schedule", systemImage: "calendar") {
                ScheduleView(rosterID: rosterID)
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

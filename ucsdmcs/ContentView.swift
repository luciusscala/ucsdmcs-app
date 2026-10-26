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
                    // Skip phone entry if the person already has one on file
                    if let entry = dataService.roster.first(where: { $0.id == rosterUUID }),
                       let phone = entry.people?.phone, !phone.isEmpty {
                        phoneEntered = "true"
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
        .onAppear {
            dataService.currentTeamId = UUID(uuidString: savedTeamID)
        }
        .onChange(of: savedTeamID) { _, newValue in
            dataService.currentTeamId = UUID(uuidString: newValue)
        }
    }

    private func personId(for rosterUUID: UUID) -> UUID {
        dataService.roster.first { $0.id == rosterUUID }?.personId ?? UUID()
    }
}

struct MainTabView: View {
    let rosterID: UUID

    var body: some View {
        TabView {
            ScheduleView(rosterID: rosterID)
                .tabItem { Label("Schedule", systemImage: "calendar") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .tint(.white)
        .modifier(TabBarMinimizeModifier())
    }
}

/// Applies `.tabBarMinimizeBehavior` on iOS 26+, no-op on older versions.
private struct TabBarMinimizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.tabBarMinimizeBehavior(.onScrollDown)
        } else {
            content
        }
    }
}

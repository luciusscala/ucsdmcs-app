import SwiftUI

struct ContentView: View {
    @AppStorage("teamID") private var savedTeamID: String = ""
    @AppStorage("rosterID") private var savedRosterID: String = ""

    var body: some View {
        Group {
            if savedTeamID.isEmpty {
                TeamSelectionView()
            } else if savedRosterID.isEmpty {
                RosterSelectionView()
            } else if let rosterUUID = UUID(uuidString: savedRosterID) {
                MainTabView(rosterID: rosterUUID)
            } else {
                TeamSelectionView()
                    .onAppear {
                        savedRosterID = ""
                        savedTeamID = ""
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: savedTeamID)
        .animation(.easeInOut(duration: 0.3), value: savedRosterID)
    }
}

struct MainTabView: View {
    let rosterID: UUID

    var body: some View {
        TabView {
            Tab("Schedule", systemImage: "calendar") {
                ScheduleView(rosterID: rosterID)
            }
            Tab("Standings", systemImage: "list.number") {
                StandingsPlaceholderView()
            }
            Tab("Settings", systemImage: "gearshape") {
                SettingsView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

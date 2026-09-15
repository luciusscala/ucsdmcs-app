import SwiftUI

struct SettingsView: View {
    @AppStorage("teamID") private var savedTeamID: String = ""
    @AppStorage("rosterID") private var savedRosterID: String = ""

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(role: .destructive) {
                        savedTeamID = ""
                        savedRosterID = ""
                    } label: {
                        HStack {
                            Text("Leave Team")
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

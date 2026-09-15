import SwiftUI

struct TeamSelectionView: View {
    @Environment(DataService.self) private var dataService
    @AppStorage("teamID") private var savedTeamID: String = ""

    var body: some View {
        NavigationStack {
            Group {
                if dataService.teams.isEmpty {
                    ProgressView("Loading teams...")
                } else {
                    List(dataService.teams) { team in
                        Button {
                            savedTeamID = team.id.uuidString
                        } label: {
                            HStack {
                                Image(systemName: "sportscourt.fill")
                                    .font(.title2)
                                    .foregroundStyle(.tint)
                                    .frame(width: 40)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(team.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    if let alias = team.dataAlias {
                                        Text(alias)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Select Your Team")
            .task {
                await dataService.fetchTeams()
            }
        }
    }
}

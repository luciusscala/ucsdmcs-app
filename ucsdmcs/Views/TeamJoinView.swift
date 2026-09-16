import SwiftUI

struct TeamSelectionView: View {
    @Environment(DataService.self) private var dataService
    @AppStorage("teamID") private var savedTeamID: String = ""
    @State private var teamCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 8) {
                    Text("Join Your Team")
                        .font(.largeTitle.weight(.bold))
                    Text("Enter the team code provided by your captain")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 16) {
                    TextField("Team Code", text: $teamCode)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.title3.monospaced())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button {
                        Task { await joinTeam() }
                    } label: {
                        Group {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Join")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 40)
                    .disabled(teamCode.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                }

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }

                Spacer()
                Spacer()
            }
            .padding()
        }
    }

    private func joinTeam() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let code = teamCode.trimmingCharacters(in: .whitespaces)
        if let team = await dataService.fetchTeamByCode(code) {
            savedTeamID = team.id.uuidString
        } else {
            errorMessage = "Invalid team code. Please try again."
        }
    }
}

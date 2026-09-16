import SwiftUI

struct SettingsView: View {
    @AppStorage("teamID") private var savedTeamID: String = ""
    @AppStorage("rosterID") private var savedRosterID: String = ""
    @AppStorage("phoneEntered") private var phoneEntered: String = ""
    @AppStorage("isAdmin") private var isAdmin: String = ""
    @Environment(DataService.self) private var dataService
    @State private var adminCode: String = ""
    @State private var adminError: String?
    @State private var isValidating = false

    private var isAdminMode: Bool { isAdmin == "true" }

    var body: some View {
        NavigationStack {
            List {
                // Admin section
                Section {
                    if isAdminMode {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            Text("Admin Mode Active")
                                .font(.body)
                            Spacer()
                        }
                        Button("Disable Admin Mode") {
                            isAdmin = ""
                        }
                    } else {
                        SecureField("Admin Code", text: $adminCode)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        Button {
                            Task { await validateAdmin() }
                        } label: {
                            HStack {
                                Text("Unlock Admin")
                                Spacer()
                                if isValidating {
                                    ProgressView()
                                }
                            }
                        }
                        .disabled(adminCode.trimmingCharacters(in: .whitespaces).isEmpty || isValidating)

                        if let adminError {
                            Text(adminError)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                } header: {
                    Text("Admin Access")
                }

                // Account section
                Section {
                    Button(role: .destructive) {
                        savedTeamID = ""
                        savedRosterID = ""
                        phoneEntered = ""
                        isAdmin = ""
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

    private func validateAdmin() async {
        isValidating = true
        adminError = nil
        defer { isValidating = false }

        guard let teamUUID = UUID(uuidString: savedTeamID) else {
            adminError = "No team selected."
            return
        }

        let code = adminCode.trimmingCharacters(in: .whitespaces)
        let valid = await dataService.validateAdminCode(teamId: teamUUID, code: code)
        if valid {
            isAdmin = "true"
            adminCode = ""
        } else {
            adminError = "Invalid admin code."
        }
    }
}

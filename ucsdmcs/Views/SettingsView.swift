import SwiftUI

struct SettingsView: View {
    @AppStorage("teamID") private var savedTeamID: String = ""
    @AppStorage("rosterID") private var savedRosterID: String = ""
    @AppStorage("phoneEntered") private var phoneEntered: String = ""
    @Environment(DataService.self) private var dataService
    @Environment(CaptainSession.self) private var captain
    @State private var adminCode: String = ""
    @State private var adminError: String?
    @State private var isValidating = false
    @State private var editingHometown: String = ""
    @State private var editingPhone: String = ""
    @FocusState private var isHometownFocused: Bool


    private var currentRosterEntry: RosterEntry? {
        guard let rosterUUID = UUID(uuidString: savedRosterID) else { return nil }
        return dataService.roster.first { $0.id == rosterUUID }
    }

    private var currentPerson: Person? {
        currentRosterEntry?.people
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile section
                if let entry = currentRosterEntry, let person = currentPerson {
                    Section {
                        HStack {
                            Text("Name")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(person.name)
                                .foregroundStyle(.tertiary)
                        }

                        if let number = entry.number {
                            HStack {
                                Text("Number")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("#\(number)")
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        HStack {
                            Text("Phone")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Phone number", text: $editingPhone)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .onChange(of: editingPhone) { _, newValue in
                                    editingPhone = newValue.filter { $0.isNumber }
                                }
                        }

                        HStack {
                            Text("Hometown")
                                .foregroundStyle(.secondary)
                            Spacer()
                            TextField("Add hometown", text: $editingHometown)
                                .multilineTextAlignment(.trailing)
                                .focused($isHometownFocused)
                        }

                        if editingHometown != (person.hometown ?? "") || editingPhone != (person.phone ?? "") {
                            Button("Save Changes") {
                                Task { await saveProfileChanges(personId: person.id) }
                            }
                            .font(.body.weight(.medium))
                        }
                    } header: {
                        Text("Profile")
                    }
                    .onAppear {
                        editingHometown = person.hometown ?? ""
                        editingPhone = person.phone ?? ""
                    }
                }

                // Admin section
                Section {
                    if captain.isCaptain {
                        HStack {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(.green)
                            Text("Admin Mode Active")
                                .font(.body)
                            Spacer()
                        }
                        Button("Disable Admin Mode") {
                            captain.lock()
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
                        captain.lock()
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
            .tint(AppTheme.practiceAccent)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("Settings")
        }
    }

    private func saveProfileChanges(personId: UUID) async {
        if editingPhone != (currentPerson?.phone ?? "") {
            await dataService.updatePhone(personId: personId, phone: editingPhone)
        }
        if editingHometown != (currentPerson?.hometown ?? "") {
            await dataService.updateHometown(personId: personId, hometown: editingHometown)
        }

        if let season = dataService.currentSeason {
            await dataService.fetchRoster(seasonId: season.id)
        }
    }

    private func validateAdmin() async {
        isValidating = true
        adminError = nil
        defer { isValidating = false }

        do {
            try await captain.unlock(
                teamId: savedTeamID,
                rosterId: savedRosterID,
                adminCode: adminCode.trimmingCharacters(in: .whitespaces)
            )
            adminCode = ""
        } catch {
            adminError = error.localizedDescription
        }
    }
}

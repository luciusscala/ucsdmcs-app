import SwiftUI

struct GameFormView: View {
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss

    // Edit mode
    var editingEventId: UUID?
    var initialDate: Date?
    var initialOpponentId: UUID?
    var initialFieldId: UUID?
    var initialIsHome: Bool?

    @State private var date: Date = Date()
    @State private var selectedOpponentId: UUID?
    @State private var selectedFieldId: UUID?
    @State private var isHome: Bool = true
    @State private var isSaving = false

    private var isEditing: Bool { editingEventId != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Opponent") {
                    if dataService.teams.isEmpty {
                        Text("Loading teams...")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Opponent", selection: $selectedOpponentId) {
                            Text("Select opponent").tag(UUID?.none)
                            ForEach(dataService.teams) { team in
                                Text(team.name).tag(UUID?.some(team.id))
                            }
                        }
                    }
                }

                Section("Location") {
                    Toggle("Home Game", isOn: $isHome)

                    if dataService.fields.isEmpty {
                        Text("Loading fields...")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Field", selection: $selectedFieldId) {
                            Text("Select a field").tag(UUID?.none)
                            ForEach(dataService.fields) { field in
                                Text(field.name).tag(UUID?.some(field.id))
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Game" : "Add Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        Task { await save() }
                    }
                    .disabled(selectedOpponentId == nil || selectedFieldId == nil || isSaving)
                }
            }
            .task {
                await dataService.fetchFields()
                await dataService.fetchTeams()
                if let initialDate { date = initialDate }
                if let initialOpponentId { selectedOpponentId = initialOpponentId }
                if let initialFieldId { selectedFieldId = initialFieldId }
                if let initialIsHome { isHome = initialIsHome }
            }
        }
    }

    private func save() async {
        guard let opponentId = selectedOpponentId,
              let fieldId = selectedFieldId else { return }
        isSaving = true
        defer { isSaving = false }

        if let eventId = editingEventId {
            await dataService.updateGame(eventId: eventId, date: date, opponentId: opponentId, fieldId: fieldId, isHome: isHome)
        } else if let seasonId = dataService.currentSeason?.id {
            await dataService.createGame(seasonId: seasonId, date: date, opponentId: opponentId, fieldId: fieldId, isHome: isHome)
        }
        dismiss()
    }
}

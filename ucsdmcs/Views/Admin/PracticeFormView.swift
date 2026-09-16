import SwiftUI

struct PracticeFormView: View {
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss

    // Edit mode: pass existing data
    var editingEventId: UUID?
    var initialDate: Date?
    var initialFieldId: UUID?
    var initialNotes: String?

    @State private var date: Date = Date()
    @State private var selectedFieldId: UUID?
    @State private var notes: String = ""
    @State private var isSaving = false

    private var isEditing: Bool { editingEventId != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Date & Time") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Location") {
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

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Practice" : "Add Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        Task { await save() }
                    }
                    .disabled(selectedFieldId == nil || isSaving)
                }
            }
            .task {
                await dataService.fetchFields()
                if let initialDate { date = initialDate }
                if let initialFieldId { selectedFieldId = initialFieldId }
                if let initialNotes { notes = initialNotes }
            }
        }
    }

    private func save() async {
        guard let fieldId = selectedFieldId else { return }
        isSaving = true
        defer { isSaving = false }

        let noteText = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes

        if let eventId = editingEventId {
            await dataService.updatePractice(eventId: eventId, date: date, fieldId: fieldId, notes: noteText)
        } else if let seasonId = dataService.currentSeason?.id {
            await dataService.createPractice(seasonId: seasonId, date: date, fieldId: fieldId, notes: noteText)
        }
        dismiss()
    }
}

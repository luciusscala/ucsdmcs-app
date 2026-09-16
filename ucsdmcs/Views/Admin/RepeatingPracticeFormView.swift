import SwiftUI

struct RepeatingPracticeFormView: View {
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDays: Set<Int> = []
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
    @State private var time: Date = {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = 18
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var selectedFieldId: UUID?
    @State private var notes: String = ""
    @State private var isSaving = false

    private let dayNames = [
        (1, "Sun"), (2, "Mon"), (3, "Tue"), (4, "Wed"),
        (5, "Thu"), (6, "Fri"), (7, "Sat")
    ]

    private var practiceCount: Int {
        guard !selectedDays.isEmpty else { return 0 }
        let calendar = Calendar.current
        var count = 0
        var current = startDate
        while current <= endDate {
            if selectedDays.contains(calendar.component(.weekday, from: current)) {
                count += 1
            }
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
            if current > endDate.addingTimeInterval(86400) { break }
        }
        return count
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Days of Week") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(dayNames, id: \.0) { day in
                            Button {
                                if selectedDays.contains(day.0) {
                                    selectedDays.remove(day.0)
                                } else {
                                    selectedDays.insert(day.0)
                                }
                            } label: {
                                Text(day.1)
                                    .font(.caption.weight(.semibold))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        selectedDays.contains(day.0)
                                            ? AnyShapeStyle(.tint.opacity(0.15))
                                            : AnyShapeStyle(.clear),
                                        in: .rect(cornerRadius: 8)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(
                                                selectedDays.contains(day.0) ? Color.accentColor : Color.secondary.opacity(0.3),
                                                lineWidth: selectedDays.contains(day.0) ? 2 : 1
                                            )
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section("Date Range") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                }

                Section("Time") {
                    DatePicker("Practice Time", selection: $time, displayedComponents: .hourAndMinute)
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

                if practiceCount > 0 {
                    Section {
                        Text("This will create **\(practiceCount)** practices")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Repeating Practices")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task { await save() }
                    }
                    .disabled(selectedDays.isEmpty || selectedFieldId == nil || isSaving)
                }
            }
            .task {
                await dataService.fetchFields()
            }
        }
    }

    private func save() async {
        guard let fieldId = selectedFieldId,
              let seasonId = dataService.currentSeason?.id else { return }
        isSaving = true
        defer { isSaving = false }

        let noteText = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes
        await dataService.createRepeatingPractices(
            seasonId: seasonId,
            days: selectedDays,
            startDate: startDate,
            endDate: endDate,
            time: time,
            fieldId: fieldId,
            notes: noteText
        )
        dismiss()
    }
}

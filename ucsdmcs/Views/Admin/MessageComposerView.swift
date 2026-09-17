import SwiftUI

struct MessageComposerView: View {
    let event: Event
    let eventID: UUID
    @Environment(DataService.self) private var dataService
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRosterIds: Set<UUID> = []
    @State private var messageText: String = ""
    @State private var isSending = false
    @State private var resultAlert: ResultAlert?

    private enum ResultAlert: Identifiable {
        case success(Int)
        case error(String)
        var id: String {
            switch self {
            case .success: return "success"
            case .error: return "error"
            }
        }
    }

    private var noResponseIds: Set<UUID> {
        Set(dataService.rosterWithoutResponse(eventId: eventID).map(\.id))
    }

    private var selectedCount: Int { selectedRosterIds.count }

    private var selectedPhones: [String] {
        dataService.roster
            .filter { selectedRosterIds.contains($0.id) }
            .compactMap { $0.people?.phone }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            List {
                // Message section
                Section("Message") {
                    TextEditor(text: $messageText)
                        .frame(minHeight: 100)
                }

                // Quick actions
                Section {
                    HStack(spacing: 12) {
                        Button("No Response") {
                            selectedRosterIds = noResponseIds
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)

                        Button("Select All") {
                            selectedRosterIds = Set(dataService.roster.map(\.id))
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)

                        Button("Clear") {
                            selectedRosterIds.removeAll()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                }

                // Roster list with checkboxes
                Section("Players (\(selectedCount) selected)") {
                    ForEach(dataService.roster) { entry in
                        Button {
                            if selectedRosterIds.contains(entry.id) {
                                selectedRosterIds.remove(entry.id)
                            } else {
                                selectedRosterIds.insert(entry.id)
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedRosterIds.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedRosterIds.contains(entry.id) ? AppTheme.buttonBlue : .secondary)

                                if let num = entry.number {
                                    Text("#\(num)")
                                        .font(.subheadline.monospaced().weight(.semibold))
                                        .foregroundStyle(.secondary)
                                        .frame(width: 36, alignment: .trailing)
                                }

                                Text(entry.displayName)
                                    .foregroundStyle(.primary)

                                Spacer()

                                // Show availability status
                                if let responses = dataService.availabilityByEvent[eventID],
                                   let response = responses.first(where: { $0.rosterId == entry.id }) {
                                    Text(response.status.label)
                                        .font(.caption)
                                        .foregroundStyle(response.status.color)
                                } else {
                                    Text("No response")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Send Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await send() }
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Text("Send (\(selectedPhones.count))")
                        }
                    }
                    .disabled(selectedPhones.isEmpty || isSending)
                }
            }
            .alert(item: $resultAlert) { alert in
                switch alert {
                case .success(let count):
                    Alert(title: Text("Sent"), message: Text("Reminder sent to \(count) players."), dismissButton: .default(Text("OK")) { dismiss() })
                case .error(let msg):
                    Alert(title: Text("Error"), message: Text(msg), dismissButton: .default(Text("OK")))
                }
            }
            .onAppear {
                selectedRosterIds = noResponseIds
                messageText = buildTemplate()
            }
        }
    }

    private func buildTemplate() -> String {
        let title: String
        switch event.eventType {
        case "practice": title = "Practice"
        case "game": title = dataService.games[event.id]?.title ?? "Game"
        case "tournament": title = dataService.tournaments[event.id]?.name ?? "Tournament"
        default: title = event.typeLabel
        }

        let dateStr = event.eventDate.formatted(.dateTime.weekday(.wide).month().day().hour().minute())

        return "Reminder: \(title) on \(dateStr). Please respond!\nucsdmcs://event/\(eventID.uuidString)"
    }

    private func send() async {
        isSending = true
        defer { isSending = false }

        let phones = selectedPhones
        do {
            try await MessageService.sendSMS(phones: phones, message: messageText)
            resultAlert = .success(phones.count)
        } catch {
            resultAlert = .error(error.localizedDescription)
        }
    }
}

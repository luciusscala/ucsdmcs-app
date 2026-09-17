import SwiftUI

struct ScheduleView: View {
    let rosterID: UUID
    @Environment(DataService.self) private var dataService
    @Environment(DeepLinkManager.self) private var deepLinkManager
    @AppStorage("isAdmin") private var isAdmin: String = ""
    @State private var showPracticeForm = false
    @State private var showRepeatingForm = false
    @State private var showGameForm = false
    @State private var navigationPath = NavigationPath()

    // Selection mode
    @State private var isSelecting = false
    @State private var selectedEventIDs: Set<UUID> = []
    @State private var showBulkDeleteAlert = false
    @State private var isBulkActionLoading = false

    private var isAdminMode: Bool { isAdmin == "true" }

    private var allEventIDs: Set<UUID> {
        Set(groupedEvents.flatMap { $0.events.map(\.event.id) })
    }

    private var allSelected: Bool {
        !allEventIDs.isEmpty && selectedEventIDs == allEventIDs
    }

    private var groupedEvents: [(date: Date, events: [EventWithAvailability])] {
        let all = dataService.eventsWithAvailability(currentRosterId: rosterID)
        let grouped = Dictionary(grouping: all) { Calendar.current.startOfDay(for: $0.event.eventDate) }
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, events: $0.value) }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if !dataService.hasLoadedSchedule {
                    ProgressView("Loading schedule...")
                } else if groupedEvents.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "No Upcoming Events",
                        subtitle: "Check back later for new practices and games."
                    )
                } else {
                    eventList
                }
            }
            .navigationTitle("Schedule")
            .navigationDestination(for: UUID.self) { eventID in
                EventDetailView(eventID: eventID, rosterID: rosterID)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isSelecting {
                        Button(allSelected ? "Deselect All" : "Select All") {
                            if allSelected {
                                selectedEventIDs.removeAll()
                            } else {
                                selectedEventIDs = allEventIDs
                            }
                        }
                    } else {
                        Button("Select") {
                            isSelecting = true
                        }
                        .foregroundStyle(.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if isSelecting {
                        Button("Done") {
                            exitSelectionMode()
                        }
                        .fontWeight(.semibold)
                    } else if isAdminMode {
                        Menu {
                            Button {
                                showPracticeForm = true
                            } label: {
                                Label("Add Practice", systemImage: "figure.run")
                            }
                            Button {
                                showRepeatingForm = true
                            } label: {
                                Label("Add Repeating Practices", systemImage: "repeat")
                            }
                            Button {
                                showGameForm = true
                            } label: {
                                Label("Add Game", systemImage: "sportscourt")
                            }
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .alert("Delete \(selectedEventIDs.count) Events?", isPresented: $showBulkDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task { await performBulkDelete() }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete the selected events and all associated availability data.")
            }
            .sheet(isPresented: $showPracticeForm) {
                PracticeFormView()
            }
            .sheet(isPresented: $showRepeatingForm) {
                RepeatingPracticeFormView()
            }
            .sheet(isPresented: $showGameForm) {
                GameFormView()
            }
            .toolbarVisibility(isSelecting ? .hidden : .automatic, for: .tabBar)
            .refreshable {
                await loadData()
            }
            .task {
                guard !dataService.hasLoadedSchedule else { return }
                await loadData()
            }
            .onChange(of: deepLinkManager.pendingEventID) { _, eventID in
                if let eventID {
                    navigationPath.append(eventID)
                    deepLinkManager.pendingEventID = nil
                }
            }
        }
    }

    // MARK: - Event List

    private var eventList: some View {
        List {
            ForEach(groupedEvents, id: \.date) { group in
                Section {
                    ForEach(group.events) { item in
                        eventCell(for: item)
                    }
                } header: {
                    Text(group.date.formatted(.dateTime.weekday(.wide).month().day()))
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay(alignment: .bottom) {
            if isSelecting && !selectedEventIDs.isEmpty {
                bulkActionBar
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Event Cell

    @ViewBuilder
    private func eventCell(for item: EventWithAvailability) -> some View {
        if isSelecting {
            Button {
                toggleSelection(item.event.id)
            } label: {
                EventRow(
                    item: item,
                    isSelecting: true,
                    isSelected: selectedEventIDs.contains(item.event.id)
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(value: item.event.id) {
                EventRow(item: item) { status in
                    Task {
                        await dataService.setAvailability(
                            eventId: item.event.id,
                            rosterId: rosterID,
                            status: status
                        )
                    }
                }
            }
        }
    }

    // MARK: - Bulk Action Bar

    private var bulkActionBar: some View {
        HStack(spacing: 0) {
            Button {
                Task { await performBulkAvailability(status: .yes) }
            } label: {
                Label("Going", systemImage: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("availabilityGreen"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }

            Button {
                Task { await performBulkAvailability(status: .no) }
            } label: {
                Label("Not Going", systemImage: "xmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("availabilityRed"))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
            }

            if isAdminMode {
                Button {
                    showBulkDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                        .contentShape(Rectangle())
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(isBulkActionLoading)
        .padding(.horizontal, 12)
        .glassEffect(.regular.interactive(), in: .capsule)
    }

    // MARK: - Actions

    private func toggleSelection(_ id: UUID) {
        if selectedEventIDs.contains(id) {
            selectedEventIDs.remove(id)
        } else {
            selectedEventIDs.insert(id)
        }
    }

    private func exitSelectionMode() {
        isSelecting = false
        selectedEventIDs.removeAll()
    }

    private func performBulkAvailability(status: AvailabilityStatus) async {
        isBulkActionLoading = true
        defer { isBulkActionLoading = false }
        await dataService.bulkSetAvailability(
            eventIds: Array(selectedEventIDs),
            rosterId: rosterID,
            status: status
        )
        exitSelectionMode()
    }

    private func performBulkDelete() async {
        isBulkActionLoading = true
        defer { isBulkActionLoading = false }
        await dataService.bulkDeleteEvents(eventIds: Array(selectedEventIDs))
        exitSelectionMode()
    }

    private func loadData() async {
        await dataService.fetchCurrentSeason()
        if let season = dataService.currentSeason {
            await dataService.fetchUpcomingEvents(seasonId: season.id)
            await dataService.fetchRoster(seasonId: season.id)
            await dataService.fetchAllAvailability(for: dataService.events.map(\.id))
            dataService.hasLoadedSchedule = true
        }
    }
}

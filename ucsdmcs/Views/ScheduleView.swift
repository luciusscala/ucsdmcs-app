import SwiftUI

struct ScheduleView: View {
    let rosterID: UUID
    @Environment(DataService.self) private var dataService

    private var groupedEvents: [(date: Date, events: [EventWithAvailability])] {
        let all = dataService.eventsWithAvailability(currentRosterId: rosterID)
        let grouped = Dictionary(grouping: all) { Calendar.current.startOfDay(for: $0.event.eventDate) }
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, events: $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if dataService.isLoading || !dataService.hasLoadedSchedule {
                    ProgressView("Loading schedule...")
                } else if groupedEvents.isEmpty {
                    EmptyStateView(
                        icon: "calendar",
                        title: "No Upcoming Events",
                        subtitle: "Check back later for new practices and games."
                    )
                } else {
                    List {
                        ForEach(groupedEvents, id: \.date) { group in
                            Section {
                                ForEach(group.events) { item in
                                    NavigationLink(value: item.event.id) {
                                        EventRow(item: item)
                                    }
                                }
                            } header: {
                                Text(group.date.formatted(.dateTime.weekday(.wide).month().day()))
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Schedule")
            .navigationDestination(for: UUID.self) { eventID in
                EventDetailView(eventID: eventID, rosterID: rosterID)
            }

            .refreshable {
                await loadData()
            }
            .task {
                guard !dataService.hasLoadedSchedule else { return }
                await loadData()
            }
        }
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

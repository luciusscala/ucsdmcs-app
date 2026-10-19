import SwiftUI

struct PlayerEventDetailView: View {
    let player: PlayerAttendanceStats
    let dateFilter: DashboardDateFilter
    @Environment(DataService.self) private var dataService

    private var events: [Event] {
        dataService.filteredSeasonEvents(since: dateFilter.startDate)
    }

    private var missedEvents: [(event: Event, reason: String)] {
        events.compactMap { event in
            let responses = dataService.allSeasonAvailability[event.id] ?? []
            if let response = responses.first(where: { $0.rosterId == player.id }) {
                if response.status == .no {
                    return (event, "Not Going")
                }
                return nil // going — not missed
            } else {
                return (event, "No Response")
            }
        }
    }

    private var attendedEvents: [Event] {
        events.filter { event in
            let responses = dataService.allSeasonAvailability[event.id] ?? []
            return responses.first(where: { $0.rosterId == player.id })?.status == .yes
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                summaryCard
                if !missedEvents.isEmpty {
                    missedSection
                }
                if !attendedEvents.isEmpty {
                    attendedSection
                }
            }
            .padding()
        }
        .navigationTitle(player.displayName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary

    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                if let num = player.displayNumber {
                    Text(num)
                        .font(.title3.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text(player.displayName)
                    .font(.title3.weight(.semibold))
                Spacer()
            }

            HStack(spacing: 0) {
                statCell(value: "\(player.goingCount)", label: "Going", color: AppTheme.availabilityGreen)
                statCell(value: "\(player.notGoingCount)", label: "Not Going", color: AppTheme.availabilityRed)
                statCell(value: "\(player.noResponseCount)", label: "No Response", color: AppTheme.availabilityAmber)
            }
        }
        .padding()
        .background(.fill.tertiary, in: .rect(cornerRadius: 12))
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold).monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Missed Events

    private var missedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(AppTheme.availabilityAmber)
                Text("Missed Events (\(missedEvents.count))")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                ForEach(Array(missedEvents.enumerated()), id: \.element.event.id) { index, item in
                    eventRow(item.event, tag: item.reason, tagColor: item.reason == "No Response" ? AppTheme.availabilityAmber : AppTheme.availabilityRed)
                    if index < missedEvents.count - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .background(.fill.tertiary, in: .rect(cornerRadius: 10))
        }
    }

    // MARK: - Attended Events

    private var attendedSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.availabilityGreen)
                Text("Attended (\(attendedEvents.count))")
                    .font(.headline)
            }

            VStack(spacing: 0) {
                ForEach(Array(attendedEvents.enumerated()), id: \.element.id) { index, event in
                    eventRow(event, tag: "Going", tagColor: AppTheme.availabilityGreen)
                    if index < attendedEvents.count - 1 {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .background(.fill.tertiary, in: .rect(cornerRadius: 10))
        }
    }

    // MARK: - Event Row

    private func eventRow(_ event: Event, tag: String, tagColor: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.typeLabel)
                    .font(.subheadline.weight(.medium))
                Text(event.eventDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(tag)
                .font(.caption.weight(.medium))
                .foregroundStyle(tagColor)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

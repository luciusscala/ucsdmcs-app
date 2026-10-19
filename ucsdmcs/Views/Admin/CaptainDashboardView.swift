import SwiftUI

struct CaptainDashboardView: View {
    @Environment(DataService.self) private var dataService
    @State private var dateFilter: DashboardDateFilter = .season

    private var stats: [PlayerAttendanceStats] {
        dataService.playerAttendanceStats(since: dateFilter.startDate)
    }

    private var filteredEvents: [Event] {
        dataService.filteredSeasonEvents(since: dateFilter.startDate)
    }

    private var teamAverageAttendance: Double {
        guard !stats.isEmpty else { return 0 }
        return stats.map(\.attendanceRate).reduce(0, +) / Double(stats.count)
    }

    private var teamAverageResponseRate: Double {
        guard !stats.isEmpty else { return 0 }
        return stats.map(\.responseRate).reduce(0, +) / Double(stats.count)
    }

    var body: some View {
        Group {
            if !dataService.hasLoadedDashboard {
                ProgressView("Loading stats...")
            } else if dataService.allSeasonEvents.isEmpty {
                EmptyStateView(
                    icon: "chart.bar",
                    title: "No Data Yet",
                    subtitle: "Attendance statistics will appear once events have been created."
                )
            } else {
                scrollContent
            }
        }
        .navigationTitle("Attendance")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard !dataService.hasLoadedDashboard else { return }
            if let season = dataService.currentSeason {
                await dataService.fetchAllSeasonEvents(seasonId: season.id)
                await dataService.fetchAllSeasonAvailability()
                dataService.hasLoadedDashboard = true
            }
        }
        .refreshable {
            if let season = dataService.currentSeason {
                dataService.hasLoadedDashboard = false
                await dataService.fetchAllSeasonEvents(seasonId: season.id)
                await dataService.fetchAllSeasonAvailability()
                dataService.hasLoadedDashboard = true
            }
        }
    }

    // MARK: - Content

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                dateFilterPicker
                teamSummaryCard
                fullRosterSection
            }
            .padding()
        }
    }

    // MARK: - Date Filter Picker

    private var dateFilterPicker: some View {
        Picker("Time Range", selection: $dateFilter) {
            ForEach(DashboardDateFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Team Summary Card

    private var teamSummaryCard: some View {
        VStack(spacing: 12) {
            Text("Overview")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                statCell(
                    value: "\(filteredEvents.count)",
                    label: "Events",
                    color: .white
                )
                statCell(
                    value: formatPercent(teamAverageResponseRate),
                    label: "Avg Response",
                    color: AppTheme.buttonBlue
                )
                statCell(
                    value: formatPercent(teamAverageAttendance),
                    label: "Avg Attendance",
                    color: AppTheme.availabilityGreen
                )
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

    // MARK: - Full Roster Section

    private var fullRosterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("All Players")
                .font(.headline)

            VStack(spacing: 0) {
                ForEach(stats) { player in
                    NavigationLink {
                        PlayerEventDetailView(
                            player: player,
                            dateFilter: dateFilter
                        )
                    } label: {
                        playerRow(player)
                    }
                    if player.id != stats.last?.id {
                        Divider().padding(.leading, 12)
                    }
                }
            }
            .background(.fill.tertiary, in: .rect(cornerRadius: 10))
        }
    }

    // MARK: - Player Row

    private func playerRow(_ player: PlayerAttendanceStats) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let num = player.displayNumber {
                    Text(num)
                        .font(.subheadline.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, alignment: .trailing)
                }
                Text(player.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 12) {
                miniStat(
                    icon: "checkmark.circle.fill",
                    value: "\(player.goingCount)",
                    color: AppTheme.availabilityGreen
                )
                miniStat(
                    icon: "xmark.circle.fill",
                    value: "\(player.notGoingCount)",
                    color: AppTheme.availabilityRed
                )
                miniStat(
                    icon: "questionmark.circle.fill",
                    value: "\(player.noResponseCount)",
                    color: AppTheme.availabilityAmber
                )
                Spacer()
                Text("\(formatPercent(player.attendanceRate)) att.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private func miniStat(icon: String, value: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(color)
            Text(value)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Helpers

    private func formatPercent(_ value: Double) -> String {
        "\(Int(value * 100))%"
    }
}

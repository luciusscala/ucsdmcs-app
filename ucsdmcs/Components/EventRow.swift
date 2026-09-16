import SwiftUI

struct EventRow: View {
    let item: EventWithAvailability
    var isSelecting: Bool = false
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            if isSelecting {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
            }
            // Leading indicator: logo for games, color bar for others
            if item.event.eventType == "game", let logoURL = item.opponentLogoURL {
                AsyncImage(url: logoURL) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange.opacity(0.15))
                        .overlay {
                            Text(String(item.game?.opponentName.prefix(3).uppercased() ?? ""))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                }
                .frame(width: 32, height: 32)
                .clipShape(.rect(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 2) {
                // Line 1: event type (+ opponent for games)
                if item.event.eventType == "game" {
                    Text("GAME")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(typeColor)
                    Text(item.game?.title ?? "Game")
                        .font(.headline)
                } else {
                    Text(item.title.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundStyle(typeColor)
                }

                // Line 2: time at location
                HStack(spacing: 0) {
                    Text(item.event.eventDate.formatted(.dateTime.hour().minute()))
                    if let location = item.location {
                        Text(" at ")
                        Text(location)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            // Status indicator
            if let status = item.currentRosterStatus {
                Image(systemName: status.icon)
                    .font(.title3)
                    .foregroundStyle(status.color)
            } else {
                Image(systemName: "circle.dashed")
                    .font(.title3)
                    .foregroundStyle(.quaternary)
            }
        }
        .padding(.vertical, 2)
    }

    private var typeColor: Color {
        switch item.event.eventType {
        case "game": return .orange
        case "practice": return .blue
        case "social": return .purple
        case "tournament": return .yellow
        default: return .gray
        }
    }
}

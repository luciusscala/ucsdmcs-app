import SwiftUI

struct PlayerAvailabilityRow: View {
    let rosterEntry: RosterEntry
    let status: AvailabilityStatus

    var body: some View {
        HStack {
            if let num = rosterEntry.number {
                Text("#\(num)")
                    .font(.subheadline.monospaced().weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
            Text(rosterEntry.displayName)
                .font(.body)
            Spacer()
        }
    }
}

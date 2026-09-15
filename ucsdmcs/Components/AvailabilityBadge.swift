import SwiftUI

struct AvailabilityBadge: View {
    let status: AvailabilityStatus
    let count: Int?

    init(status: AvailabilityStatus, count: Int? = nil) {
        self.status = status
        self.count = count
    }

    var body: some View {
        HStack(spacing: 4) {
            if count == nil {
                Image(systemName: status.icon)
                    .font(.caption2)
            }
            Text(count != nil ? "\(count!)" : status.label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.15), in: .capsule)
        .foregroundStyle(status.color)
    }
}

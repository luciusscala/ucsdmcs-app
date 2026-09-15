import SwiftUI

struct AvailabilityPicker: View {
    let selected: AvailabilityStatus?
    let onSelect: (AvailabilityStatus) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(AvailabilityStatus.allCases, id: \.self) { status in
                Button {
                    onSelect(status)
                } label: {
                    Text(status.label)
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            selected == status
                                ? status.color.opacity(0.15)
                                : Color.clear,
                            in: .rect(cornerRadius: 12)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(
                                    status.color.opacity(selected == status ? 1 : 0.3),
                                    lineWidth: selected == status ? 2 : 1
                                )
                        )
                }
                .foregroundStyle(status.color)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: selected)
            }
        }
    }
}

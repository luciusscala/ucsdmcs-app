import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(subtitle))
    }
}

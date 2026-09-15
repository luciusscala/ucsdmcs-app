import SwiftUI

struct StandingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Coming Soon",
                systemImage: "list.number",
                description: Text("Standings will appear here once the season is underway.")
            )
            .navigationTitle("Standings")
        }
    }
}

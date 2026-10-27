import SwiftUI

struct MandatoryUpdateView: View {
    @Environment(\.openURL) private var openURL

    // Replace with your actual App Store URL once published
    private let appStoreURL = URL(string: "https://apps.apple.com/us/app/fixture-management/id6812923949")!

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.buttonBlue)

            VStack(spacing: 8) {
                Text("Update Required")
                    .font(.largeTitle.weight(.bold))
                Text("A new version of the app is available. Please update to continue.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                openURL(appStoreURL)
            } label: {
                Text("Update Now")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

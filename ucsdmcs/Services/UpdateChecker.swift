import Foundation
import Supabase

@Observable
final class UpdateChecker {

    var updateRequired = false

    private var supabase: SupabaseClient { SupabaseConfig.client }

    /// Fetches `min_version` from the `app_config` table and compares it
    /// against the app's current bundle version. Fails open — if the
    /// fetch fails or the table is empty, the app is not blocked.
    func check() async {
        do {
            let rows: [[String: String]] = try await supabase
                .from("app_config")
                .select("min_version")
                .limit(1)
                .execute()
                .value

            guard let minVersion = rows.first?["min_version"],
                  let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            else {
                updateRequired = false
                return
            }

            updateRequired = isVersion(currentVersion, lessThan: minVersion)
        } catch {
            // Fail open: don't block the app if we can't reach config
            updateRequired = false
        }
    }

    /// Semantic version comparison: "1.2.3" < "1.3.0"
    /// Splits on ".", compares each numeric component left to right.
    /// Missing components are treated as 0 (e.g., "1.2" == "1.2.0").
    private func isVersion(_ current: String, lessThan minimum: String) -> Bool {
        let currentParts = current.split(separator: ".").compactMap { Int($0) }
        let minimumParts = minimum.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(currentParts.count, minimumParts.count)

        for i in 0..<maxCount {
            let c = i < currentParts.count ? currentParts[i] : 0
            let m = i < minimumParts.count ? minimumParts[i] : 0
            if c < m { return true }
            if c > m { return false }
        }
        return false // equal versions
    }
}

import Foundation

/// Captain (admin) mode. Unlocking trades the team's admin code for a token
/// signed by the website and kept in the Keychain. The server checks that
/// token on every captain-only request, so the mode can't just be switched
/// on from the device.
@Observable
final class CaptainSession {
    private static let tokenKey = "captainToken"

    private(set) var token: String? = Keychain.read(CaptainSession.tokenKey)

    var isCaptain: Bool { token != nil }

    func unlock(teamId: String, rosterId: String, adminCode: String) async throws {
        struct Request: Encodable { let teamId, rosterId, adminCode: String }
        struct Response: Decodable { let token: String }

        let response: Response = try await APIClient.post(
            "captain/unlock",
            body: Request(teamId: teamId, rosterId: rosterId, adminCode: adminCode)
        )
        Keychain.save(response.token, for: Self.tokenKey)
        token = response.token
    }

    func lock() {
        Keychain.delete(Self.tokenKey)
        token = nil
    }

    /// Texts `message` to the chosen players. The server looks up their
    /// numbers, so none leave the database.
    func sendReminder(to rosterIds: Set<UUID>, message: String) async throws -> ReminderResult {
        struct Request: Encodable { let rosterIds: [UUID], message: String }

        return try await APIClient.post(
            "reminders",
            body: Request(rosterIds: Array(rosterIds), message: message),
            token: token
        )
    }
}

struct ReminderResult: Decodable {
    let sent: Int
    let failed: Int
}

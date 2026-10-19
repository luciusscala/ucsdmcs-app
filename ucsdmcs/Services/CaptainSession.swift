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
        guard let token else {
            throw APIClient.ServerError(errorDescription: "Admin mode expired. Please re-unlock in Settings.")
        }

        struct Request: Encodable { let rosterIds: [UUID], message: String }

        do {
            return try await APIClient.post(
                "reminders",
                body: Request(rosterIds: Array(rosterIds), message: message),
                token: token
            )
        } catch let error as APIClient.ServerError {
            // If the server says the token is invalid, clear it so the user
            // sees they need to re-unlock rather than silently failing.
            let msg = (error.errorDescription ?? "").lowercased()
            if msg.contains("admin") || msg.contains("unauthorized") || msg.contains("token") {
                lock()
            }
            throw error
        }
    }
}

struct ReminderResult: Decodable {
    let sent: Int
    let failed: Int
}

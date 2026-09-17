import Foundation

enum MessageService {
    // Configure this to your FastAPI backend URL
    // NOT DEPLOYED YET
    static let baseURL = "PLACEHOLDER"

    static func sendSMS(phones: [String], message: String) async throws {
        guard let url = URL(string: "\(baseURL)/send-sms") else {
            throw MessageError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "phones": phones,
            "message": message
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw MessageError.serverError(errorBody)
        }
    }

    enum MessageError: LocalizedError {
        case invalidURL
        case serverError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid server URL."
            case .serverError(let msg): return "Server error: \(msg)"
            }
        }
    }
}

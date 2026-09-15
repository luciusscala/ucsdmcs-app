import Foundation
import Supabase

enum SupabaseConfig {
    private static let supabaseURL = "https://uossjvkayfchytbycumd.supabase.co"

    static let client = SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVvc3NqdmtheWZjaHl0YnljdW1kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg1MzcxNTEsImV4cCI6MjEwNDExMzE1MX0.knGwopm8n4G1yvRO1couvin7bbOAGOT6ITSdrtB1CEo"
    )

    static func storageURL(for path: String, bucket: String = "logos") -> URL? {
        try? client.storage.from(bucket).getPublicURL(path: path)
    }
}

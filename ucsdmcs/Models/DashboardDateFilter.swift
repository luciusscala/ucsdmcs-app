import Foundation

enum DashboardDateFilter: String, CaseIterable, Identifiable {
    case week = "1 Week"
    case twoWeeks = "2 Weeks"
    case month = "1 Month"
    case season = "All Season"

    var id: String { rawValue }

    var startDate: Date? {
        let cal = Calendar.current
        switch self {
        case .week:     return cal.date(byAdding: .day, value: -7, to: Date())
        case .twoWeeks: return cal.date(byAdding: .day, value: -14, to: Date())
        case .month:    return cal.date(byAdding: .month, value: -1, to: Date())
        case .season:   return nil
        }
    }
}

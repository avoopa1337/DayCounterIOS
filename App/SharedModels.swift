import Foundation

struct TrackedDate: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date

    init(id: UUID = UUID(), title: String, date: Date) {
        self.id = id
        self.title = title
        self.date = date
    }

    func daysPassed(from referenceDate: Date = Date()) -> Int {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: date)
        let end = calendar.startOfDay(for: referenceDate)
        let components = calendar.dateComponents([.day], from: start, to: end)
        return max(0, components.day ?? 0)
    }
}

enum SharedStorage {
    static let defaultSuiteName = "group.com.personal.daycounter.shared"
    private static let datesKey = "tracked_dates_v1"
    private static let selectedWidgetIdKey = "selected_widget_date_id_v1"

    static var suiteName: String {
        if let appGroups = Bundle.main.object(forInfoDictionaryKey: "AppGroups") as? [String],
           let first = appGroups.first, !first.isEmpty {
            return first
        }
        return defaultSuiteName
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }

    static func loadDates() -> [TrackedDate] {
        guard let data = defaults.data(forKey: datesKey),
              let decoded = try? JSONDecoder().decode([TrackedDate].self, from: data) else {
            return []
        }
        return decoded
    }

    static func saveDates(_ dates: [TrackedDate]) {
        if let encoded = try? JSONEncoder().encode(dates) {
            defaults.set(encoded, forKey: datesKey)
        }
    }

    static func loadSelectedWidgetId() -> UUID? {
        guard let raw = defaults.string(forKey: selectedWidgetIdKey) else { return nil }
        return UUID(uuidString: raw)
    }

    static func saveSelectedWidgetId(_ id: UUID?) {
        defaults.set(id?.uuidString, forKey: selectedWidgetIdKey)
    }
}
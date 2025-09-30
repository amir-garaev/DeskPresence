import Foundation

// MARK: - AppFormat

enum AppFormat {
    static func hms(_ sec: Double) -> String {
        let s = Int(max(0, sec.rounded()))
        return String(format: "%02d:%02d:%02d", s/3600, (s%3600)/60, s%60)
    }

    private static let _shortDateTime: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df
    }()

    private static let _mediumDate: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df
    }()

    static func dateShortTime(_ d: Date) -> String {
        _shortDateTime.string(from: d)
    }

    static func dateMedium(_ d: Date) -> String {
        _mediumDate.string(from: d)
    }
}

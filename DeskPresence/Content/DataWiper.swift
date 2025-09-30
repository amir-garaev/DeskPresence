import Foundation

// MARK: - DataWiper

enum DataWiper {

    // MARK: API

    static func wipeAllData(store: SessionStore, tracker: SessionTracker) {
        if tracker.active { tracker.stop() }

        store.clear()
        CSVLogger.shared.flushAndClose()

        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DeskPresence", isDirectory: true)
        let csvURL = dir.appendingPathComponent("sessions.csv")
        try? FileManager.default.removeItem(at: csvURL)

        if let items = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
           items.isEmpty {
            try? FileManager.default.removeItem(at: dir)
        }

        tracker.sessionName = ""
        tracker.currentSec = 0
        tracker.totalSec = 0
    }
}

import Foundation

// MARK: - LogEvent

enum LogEvent: String {
    case start = "START"
    case chunk = "CHUNK"
    case stop = "STOP"
    case stopApp = "STOP_APP"
    case heartbeat = "HEARTBEAT"
}

// MARK: - CSVLogger

final class CSVLogger {
    static let shared = CSVLogger()
    private init() {}

    // MARK: State

    private var handle: FileHandle?
    private var lastHeartbeat: Date = .distantPast
    var heartbeatInterval: TimeInterval = 60

    private static let tsDF: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd HH:mm:ss"
        df.locale = Locale(identifier: "en_US_POSIX")
        return df
    }()

    // MARK: Paths

    private var dirURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("DeskPresence", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private var fileURL: URL {
        dirURL.appendingPathComponent("sessions.csv")
    }

    // MARK: Open/Close

    func openIfNeeded() {
        if handle != nil { return }

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let header = "ts,event,session,total_sec,total_hms,duration_sec,duration_hms\n"
            try? Data(header.utf8).write(to: fileURL)
        }

        handle = try? FileHandle(forWritingTo: fileURL)
        if let h = handle {
            if #available(macOS 13.0, *) {
                _ = try? h.seekToEnd()
            } else {
                h.seekToEndOfFile()
            }
        }
    }

    func flushAndClose() {
        guard let h = handle else { return }
        if #available(macOS 13.0, *) {
            try? h.synchronize()
            try? h.close()
        } else {
            h.synchronizeFile()
            h.closeFile()
        }
        handle = nil
    }

    // MARK: Logging

    func log(_ ev: LogEvent, name: String, duration: Double? = nil, total: Double? = nil) {
        openIfNeeded()
        guard let h = handle else { return }

        let ts  = Self.tsDF.string(from: .now)
        let dur = max(0, duration ?? 0)
        let tot = max(0, total ?? 0)

        let line =
            "\(ts)," +
            "\(ev.rawValue)," +
            "\(csvEscape(name))," +
            "\(Int(tot))," +
            "\(AppFormat.hms(tot))," +
            "\(Int(dur))," +
            "\(AppFormat.hms(dur))\n"

        if let data = line.data(using: .utf8) {
            if #available(macOS 13.0, *) {
                try? h.write(contentsOf: data)
            } else {
                h.write(data)
            }
        }
    }

    // MARK: Heartbeat

    func heartbeatIfNeeded(name: String, total: Double) {
        let now = Date()
        guard now.timeIntervalSince(lastHeartbeat) >= max(5, heartbeatInterval) else { return }
        log(.heartbeat, name: name, total: total)
        lastHeartbeat = now
    }

    // MARK: CSV utils

    private func csvEscape(_ s: String) -> String {
        // Экранируем двойные кавычки и всегда оборачиваем в кавычки
        let escaped = s.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
}

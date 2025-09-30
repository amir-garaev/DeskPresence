import Foundation
import Combine

// MARK: - SessionTracker

@MainActor
final class SessionTracker: ObservableObject {
    // MARK: Published State
    @Published var sessionName: String = ""
    @Published var active: Bool = false
    @Published var facePresent: Bool = false
    @Published var currentSec: Double = 0
    @Published var totalSec: Double = 0

    // MARK: Config
    var startGrace: TimeInterval = 0.0
    var stopGrace:  TimeInterval = 2.5

    // MARK: Dependencies
    weak var store: SessionStore?

    // MARK: Internal State
    private var sessionStart: Date?
    private var seenFaceSince: Date?
    private var lastSeenFace: Date?
    private var absoluteStart: Date?

    // MARK: Public API

    func start() {
        guard !active else { return }
        if sessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            sessionName = "Session " + AppFormat.dateShortTime(.now)
        }
        active = true
        absoluteStart = Date()
        sessionStart = nil
        seenFaceSince = nil
        lastSeenFace = nil
        totalSec = 0

        CSVLogger.shared.openIfNeeded()
        CSVLogger.shared.log(.start, name: sessionName, total: totalSec)
    }

    func stop(final: Bool = false) {
        guard active else { return }

        if let start = sessionStart {
            let dur = max(0, Date().timeIntervalSince(start))
            totalSec += dur
            currentSec = 0
            sessionStart = nil
            CSVLogger.shared.log(.chunk, name: sessionName, duration: dur, total: totalSec)
        }

        active = false
        let ended = Date()

        if let begun = absoluteStart {
            let rec = SessionRecord(
                id: UUID(),
                name: sessionName,
                startedAt: begun,
                endedAt: ended,
                totalSec: totalSec
            )
            store?.add(rec)
        }
        absoluteStart = nil

        CSVLogger.shared.log(final ? .stopApp : .stop, name: sessionName, total: totalSec)
        if final { CSVLogger.shared.flushAndClose() }
    }

    func updateFace(present: Bool, now: Date = .init()) {
        facePresent = present

        if present {
            if seenFaceSince == nil { seenFaceSince = now }
            lastSeenFace = now
        } else {
            seenFaceSince = nil
        }

        guard active else { currentSec = 0; return }

        if sessionStart == nil, present, let s = seenFaceSince, now.timeIntervalSince(s) >= startGrace {
            sessionStart = now
        }

        if let last = lastSeenFace, !present, now.timeIntervalSince(last) >= stopGrace {
            if let start = sessionStart {
                let dur = last.timeIntervalSince(start)
                totalSec += max(0, dur)
                currentSec = 0
                sessionStart = nil
                CSVLogger.shared.log(.chunk, name: sessionName, duration: dur, total: totalSec)
            }
        }

        if let start = sessionStart {
            currentSec = now.timeIntervalSince(start)
        } else {
            currentSec = 0
        }
    }

    func appWillTerminate() {
        if active { stop(final: true) } else { CSVLogger.shared.flushAndClose() }
    }
}

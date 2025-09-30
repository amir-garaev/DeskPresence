import Foundation
import AppKit

enum AppFiles {
    // MARK: Paths
    static var sessionsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DeskPresence", isDirectory: true)
    }

    // MARK: Actions
    enum RevealStyle { case open, reveal }

    static func showSessionsFolder(_ style: RevealStyle = .reveal) {
        try? FileManager.default.createDirectory(at: sessionsDir, withIntermediateDirectories: true)

        switch style {
        case .open:
            NSWorkspace.shared.open(sessionsDir)
        case .reveal:
            NSWorkspace.shared.activateFileViewerSelecting([sessionsDir])
        }
    }
}

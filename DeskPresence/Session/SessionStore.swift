import Foundation
import Combine
import SwiftUI

// MARK: - SessionStore

@MainActor
final class SessionStore: ObservableObject {
    // MARK: Published State
    @Published private(set) var sessions: [SessionRecord] = []

    // MARK: Storage
    private var storageURL: URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DeskPresence", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("sessions.json")
    }

    // MARK: Lifecycle
    init() { load() }

    // MARK: Public API
    func load() {
        guard let data = try? Data(contentsOf: storageURL) else {
            sessions = []
            return
        }
        sessions = (try? JSONDecoder.withISO.decode([SessionRecord].self, from: data)) ?? []
    }

    func add(_ rec: SessionRecord) {
        sessions.insert(rec, at: 0)
        persist()
    }

    func delete(at offsets: IndexSet) {
        sessions.remove(atOffsets: offsets)
        persist()
    }

    func delete(id: UUID) {
        if let i = sessions.firstIndex(where: { $0.id == id }) {
            sessions.remove(at: i)
            persist()
        }
    }

    func clear() {
        sessions.removeAll()
        persist()
    }

    // MARK: Persistence
    private func persist() {
        guard let data = try? JSONEncoder.withISO.encode(sessions) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}

// MARK: - Model

struct SessionRecord: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var startedAt: Date
    var endedAt: Date
    var totalSec: Double
}

// MARK: - JSON Coding Helpers

private extension JSONEncoder {
    static let withISO: JSONEncoder = {
        let enc = JSONEncoder()
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        enc.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(df.string(from: date))
        }
        return enc
    }()
}

private extension JSONDecoder {
    static let withISO: JSONDecoder = {
        let dec = JSONDecoder()
        let df = ISO8601DateFormatter()
        df.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        dec.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let s = try c.decode(String.self)
            if let d = df.date(from: s) { return d }
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "Invalid ISO8601 date: \(s)"
            ))
        }
        return dec
    }()
}

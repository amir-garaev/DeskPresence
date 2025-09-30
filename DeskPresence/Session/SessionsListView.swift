import SwiftUI
import AppKit

// MARK: - SessionsListView

struct SessionsListView: View {
    // MARK: Props
    @ObservedObject var store: SessionStore
    var onClose: (() -> Void)? = nil

    // MARK: Env
    @Environment(\.dismiss) private var dismiss

    // MARK: State
    @State private var pendingDelete: SessionRecord?

    // MARK: Body
    var body: some View {
        VStack(alignment: .leading) {
            header

            List {
                ForEach(store.sessions) { s in
                    row(for: s)
                        .padding(.vertical, 4)
                }
                .onDelete(perform: store.delete)
            }
        }
        .padding()
        .frame(minWidth: 520, minHeight: 360)
        .alert("Delete this session?",
               isPresented: Binding(
                    get: { pendingDelete != nil },
                    set: { if !$0 { pendingDelete = nil } }
               ),
               actions: {
                    Button("Cancel", role: .cancel) { pendingDelete = nil }
                    Button("Delete", role: .destructive) {
                        if let s = pendingDelete { store.delete(id: s.id) }
                        pendingDelete = nil
                    }
               },
               message: {
                   if let s = pendingDelete {
                       Text("“\(s.name)” • \(AppFormat.hms(s.totalSec))")
                           .monospacedDigit()
                   }
               })
    }

    // MARK: Header
    private var header: some View {
        HStack {
            Text("Saved Sessions").font(.title2).bold()
            Spacer()
            Button("Sessions Folder") { AppFiles.showSessionsFolder(.open) }
            Button(role: .destructive) {
                store.clear()
            } label: {
                Label("Clear All", systemImage: "trash")
            }
            .disabled(store.sessions.isEmpty)

            Button {
                if let onClose { onClose() } else { dismiss() }
            } label: {
                Label("Close", systemImage: "xmark")
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding(.bottom, 8)
    }

    // MARK: Row
    private func row(for s: SessionRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(s.name).font(.headline)
                Text("\(AppFormat.dateShortTime(s.startedAt)) → \(AppFormat.dateShortTime(s.endedAt))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(AppFormat.hms(s.totalSec))
                .font(.system(.body, design: .monospaced))
                .monospacedDigit()

            Button {
                pendingDelete = s
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Delete this session")
            .foregroundStyle(.red)
            .keyboardShortcut(.delete, modifiers: [])
            .contextMenu {
                Button(role: .destructive) {
                    store.delete(id: s.id)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
}

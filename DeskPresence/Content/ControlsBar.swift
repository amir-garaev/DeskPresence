import SwiftUI

// MARK: - ControlsBar

struct ControlsBar: View {
    // MARK: Callbacks
    var onShowSessions: () -> Void
    var onShowDynamics: () -> Void
    var onDeleteAll:    () -> Void

    // MARK: Layout
    var topInset: CGFloat = 10

    var body: some View {
        ZStack(alignment: .topLeading) {
            // фон левой колонки
            Rectangle().fill(.thinMaterial)

            // контент
            VStack(alignment: .leading, spacing: 8) {
                ControlButton(icon: "list.bullet.rectangle", title: "Sessions", action: onShowSessions)
                ControlButton(icon: "chart.bar",             title: "Dynamics", action: onShowDynamics)
                ControlButton(icon: "trash",                 title: "Delete",   tint: .red, action: onDeleteAll)

                Spacer(minLength: 0)

                // ссылка в самом низу
                Link(destination: AppConst.repoURL) {
                    Label("GitHub", systemImage: "link")
                        .font(.footnote)
                }
                .tint(.secondary)
            }
            .padding(.top, topInset)
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - ControlButton

private struct ControlButton: View {
    let icon: String
    let title: String
    var tint: Color? = nil
    let action: () -> Void

    // MARK: State
    @State private var hovering = false
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.title3)
                Text(title).font(.body)
                Spacer(minLength: 0)
            }
            .foregroundStyle(tint ?? .primary)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.quaternary)
                    .opacity(hovering ? (isEnabled ? 0.5 : 0.25) : 0)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeInOut(duration: 0.12), value: hovering)
    }
}

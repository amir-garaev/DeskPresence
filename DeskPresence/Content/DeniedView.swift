import SwiftUI

// MARK: - DeniedView

struct DeniedView: View {
    // MARK: Props
    let statusText: String
    let openSettings: () -> Void
    let tryAgain: () -> Void
    let backToIntro: () -> Void

    // MARK: Body
    var body: some View {
        VStack(spacing: 12) {
            Text("Camera status: \(statusText)")
                .font(.system(.title3, design: .monospaced))

            Text("❌ Camera access is required for DeskPresence to work.")
                .foregroundColor(.red)

            Text("You can enable access in System Settings → Privacy & Security → Camera.")
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Open Camera Settings", action: openSettings)
                Button("Try Again", action: tryAgain)
                Button("Back to Intro", action: backToIntro)
            }
        }
        .padding(24)
    }
}

import SwiftUI

// MARK: - StartButton

struct StartButton: View {
    // MARK: Props
    @ObservedObject var tracker: SessionTracker
    let cam: CameraController
    var titleStart: String = "Start"
    var titleStop:  String = "Stop"

    // MARK: Body
    var body: some View {
        Button {
            if tracker.active {
                tracker.stop()
            } else {
                tracker.start()
                tracker.updateFace(present: cam.facePresent)
            }
        } label: {
            HStack {
                Spacer(minLength: 0)
                Image(systemName: tracker.active ? "pause.fill" : "play.fill")
                Text(tracker.active ? titleStop : titleStart)
                Spacer(minLength: 0)
            }
            .font(.system(size: 16, weight: .semibold))
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tracker.active ? Color.red : Color.accentColor)
            )
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .focusable(false)
    }
}

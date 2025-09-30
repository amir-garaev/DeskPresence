import SwiftUI

// MARK: - CameraPreviewSheet

struct CameraPreviewSheet: View {
    @ObservedObject var cam: CameraController
    var onClose: (() -> Void)? = nil

    // MARK: Env
    @Environment(\.dismiss) private var dismiss

    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Camera Preview")
                    .font(.title3).bold()
                Spacer()
                Button {
                    cam.publishFrames = false
                    if let onClose { onClose() } else { dismiss() }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
            }

            CameraView(cam: cam)
                .background(.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(16)
        .onAppear { cam.publishFrames = true }
        .onDisappear { cam.publishFrames = false }
    }
}

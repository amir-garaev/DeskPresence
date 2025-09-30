import SwiftUI
import AVFoundation

// MARK: - IntroView

struct IntroView: View {
    // MARK: Props
    let cam: CameraController
    var onAgree: () -> Void
    var onDecline: () -> Void

    // MARK: State
    @State private var showCameraSheet = false

    // MARK: Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DeskPresence")
                    .font(.title2).bold()
                Spacer()
                Link("GitHub", destination: AppConst.repoURL)
                    .font(.callout.weight(.semibold))
            }

            Text("Tracks your computer time by checking if your face is visible to the camera. All processing is on-device; nothing is uploaded.")
                .font(.body)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Label("Open-source", systemImage: "chevron.left.forwardslash.chevron.right")
                Label("On-device processing", systemImage: "cpu")
                Label("No frames stored or uploaded", systemImage: "nosign")
                Label("Anonymous CSV logs (local)", systemImage: "doc.text")
            }
            .font(.body)

            Text("By continuing, you agree to grant camera access.")
                .font(.body)

            HStack(spacing: 10) {
                Button("Agree & Continue") {
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        DispatchQueue.main.async {
                            if granted {
                                cam.publishFrames = true
                                showCameraSheet = true
                            } else {
                                onDecline()
                            }
                        }
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Decline", action: onDecline)
                    .buttonStyle(.bordered)
            }
        }
        .padding(20)
        .frame(maxWidth: 520)
        .sheet(isPresented: $showCameraSheet, onDismiss: {
            cam.publishFrames = false
        }) {
            VStack(spacing: 12) {
                CameraPreviewSheet(cam: cam) { showCameraSheet = false }
                    .frame(width: AppConst.cameraSheetSize.width,
                           height: AppConst.cameraSheetSize.height)

                Button("Next") {
                    cam.publishFrames = false
                    showCameraSheet = false
                    onAgree()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return, modifiers: [])
                .padding(.top, 4)
            }
            .padding(16)
        }
    }
}

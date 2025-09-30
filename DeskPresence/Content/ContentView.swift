import SwiftUI
import AVFoundation
import Combine

// MARK: - ContentView

struct ContentView: View {
    // MARK: - Camera & Permissions
    @State private var status  = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var granted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized

    // MARK: - Flow
    @State private var showIntro: Bool = AVCaptureDevice.authorizationStatus(for: .video) != .authorized
    @State private var declined  = false

    // MARK: - Tracking
    @StateObject private var cam     = CameraController()
    @StateObject private var tracker = SessionTracker()

    // MARK: - Ticks
    @State private var tick = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    // MARK: - Data & Screens
    @StateObject private var store = SessionStore()
    @State private var showSessions = false
    @State private var showDynamics = false

    // MARK: - Alerts
    @State private var showDeleteConfirm = false

    // MARK: - Env
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body
    var body: some View {
        Group {
            if showIntro {
                IntroView(
                    cam: cam,
                    onAgree: {
                        refreshStatus()
                        showIntro = false
                    },
                    onDecline: {
                        showIntro = false
                        declined = true
                    }
                )
                .frame(width: AppConst.introWidth, height: AppConst.introHeight)

            } else {
                if granted {

                    // MARK: Layout: Split 20% (left) / 80% (right)
                    VStack(alignment: .leading, spacing: 0) {
                        GeometryReader { geo in
                            HStack(spacing: 0) {

                                // MARK: Left: Controls
                                ControlsBar(
                                    onShowSessions: { showSessions = true },
                                    onShowDynamics: { showDynamics = true },
                                    onDeleteAll:    { showDeleteConfirm = true },
                                    topInset: 30
                                )
                                .frame(width: geo.size.width * 0.20, height: geo.size.height)
                                .ignoresSafeArea(.all)

                                // MARK: Right: Camera + Status + Timers + Start
                                VStack {
                                    Spacer(minLength: 0)

                                    VStack(spacing: 20) {
                                        SessionNameRow(name: $tracker.sessionName)
                                            .padding(.horizontal, 4)

                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(.ultraThinMaterial)

                                            CameraView(cam: cam)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .strokeBorder(.quaternary, lineWidth: 1)
                                                )
                                        }
                                        .frame(maxWidth: .infinity)
                                        .aspectRatio(3/2, contentMode: .fit)

                                        FaceStatusView(facePresent: tracker.facePresent)

                                        TimersRow(tracker: tracker)

                                        StartButton(tracker: tracker, cam: cam)
                                    }
                                    .padding(16)
                                    .frame(maxWidth: .infinity)

                                    Spacer(minLength: 0)
                                }
                                .frame(width: geo.size.width * 0.80, height: geo.size.height)
                            }
                        }
                    }

                    // MARK: - Lifecycle & Ticks
                    .onAppear {
                        cam.publishFrames = true
                        cam.start()
                        tracker.startGrace = 0.0
                        tracker.stopGrace  = 2.5
                        tracker.store = store
                    }
                    .onDisappear {
                        cam.stop()
                        tracker.appWillTerminate()
                    }
                    .onChange(of: cam.facePresent) { _, present in
                        tracker.updateFace(present: present)
                        CSVLogger.shared.heartbeatIfNeeded(
                            name: tracker.sessionName,
                            total: tracker.totalSec + tracker.currentSec
                        )
                    }
                    .onReceive(tick) { _ in
                        tracker.updateFace(present: cam.facePresent)
                        CSVLogger.shared.heartbeatIfNeeded(
                            name: tracker.sessionName,
                            total: tracker.totalSec + tracker.currentSec
                        )
                    }

                    // MARK: - Sheets
                    .sheet(isPresented: $showDynamics) {
                        DynamicsView(store: store)
                            .frame(minWidth: 640, minHeight: 480)
                    }
                    .sheet(isPresented: $showSessions) {
                        SessionsListView(store: store)
                            .frame(minWidth: 560, minHeight: 380)
                            .padding(12)
                    }

                    // MARK: - Alerts
                    .alert("Delete all data?",
                           isPresented: $showDeleteConfirm) {
                        Button("Delete", role: .destructive) {
                            DataWiper.wipeAllData(store: store, tracker: tracker)
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This removes all saved sessions and the CSV log from your Documents/DeskPresence folder.")
                    }

                } else if declined || status == .denied || status == .restricted {
                    DeniedView(
                        statusText: statusText(status),
                        openSettings: { SystemSettings.openCameraPrivacyPane() },
                        tryAgain:     { declined = false; requestCamera() },
                        backToIntro:  { showIntro = true; declined = false }
                    )
                    .frame(width: AppConst.mainWidth, height: AppConst.mainHeight)

                } else {
                    VStack(spacing: 12) {
                        Text("Camera status: \(statusText(status))")
                            .font(.system(.title3, design: .monospaced))
                        Button("Request Camera Access") { requestCamera() }
                        Button("Back to Intro") { showIntro = true }
                    }
                    .padding(24)
                    .frame(width: AppConst.mainWidth, height: AppConst.mainHeight)
                }
            }
        }
        // MARK: - Scene Phase
        .onChange(of: status) { _, newStatus in
            granted = (newStatus == .authorized)
            if granted { showIntro = false }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .inactive || newPhase == .background {
                tracker.appWillTerminate()
            }
        }
    }

    // MARK: - Helpers

    private func refreshStatus() {
        status = AVCaptureDevice.authorizationStatus(for: .video)
        granted = (status == .authorized)
        if granted { showIntro = false }
    }

    private func requestCamera() {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async { self.refreshStatus() }
        }
    }

    private func statusText(_ s: AVAuthorizationStatus) -> String {
        switch s {
        case .authorized:     return "authorized"
        case .denied:         return "denied"
        case .restricted:     return "restricted"
        case .notDetermined:  return "notDetermined"
        @unknown default:     return "unknown"
        }
    }
}

import Foundation
import AVFoundation
import AppKit
import Combine
import Vision

// MARK: - CameraController

@MainActor
final class CameraController: NSObject, ObservableObject {

    // MARK: State
    @Published var frame: NSImage?
    @Published var facePresent: Bool = false
    var publishFrames: Bool = false

    // MARK: Session
    private let session = AVCaptureSession()
    private let output  = AVCaptureVideoDataOutput()

    // MARK: Detection
    private var frameCounter = 0
    private let detectEveryN = 2

    // MARK: Lifecycle
    func start() {
        configureSession()
        session.startRunning()
    }

    func stop() {
        session.stopRunning()
    }

    // MARK: Configuration
    private func configureSession() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(for: .video),
              let input  = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            print("No camera input")
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: .main)

        if session.canAddOutput(output) { session.addOutput(output) }

        if let conn = output.connection(with: .video) {
            conn.automaticallyAdjustsVideoMirroring = false
            conn.isVideoMirrored = false
        }

        session.commitConfiguration()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraController: AVCaptureVideoDataOutputSampleBufferDelegate {
    @MainActor
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        frameCounter &+= 1
        let shouldDetect = (frameCounter % detectEveryN == 0)

        if shouldDetect {
            let handler = VNImageRequestHandler(cvPixelBuffer: pb, orientation: .leftMirrored)
            let request = VNDetectFaceRectanglesRequest()
            _ = try? handler.perform([request])
            let count = request.results?.count ?? 0
            self.facePresent = (count > 0)
        }

        if publishFrames {
            let img = OpenCVWrapper.image(from: pb)
            self.frame = img
        }
    }
}

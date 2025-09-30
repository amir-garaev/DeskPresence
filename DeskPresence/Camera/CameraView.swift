import SwiftUI

// MARK: - CameraView

struct CameraView: View {
    @ObservedObject var cam: CameraController

    var body: some View {
        ZStack {
            if let img = cam.frame {
                GeometryReader { geo in
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }
            } else {
                ProgressView("Starting camera…")
                    .controlSize(.large)
            }
        }
    }
}

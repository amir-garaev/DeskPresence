import SwiftUI

// MARK: - FaceStatusView

struct FaceStatusView: View {
    // MARK: Props
    let facePresent: Bool

    // MARK: Derived
    private var text: String { facePresent ? "Face in frame" : "Face not visible" }
    private var color: Color { facePresent ? .green : .orange }

    // MARK: Body
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(text)
                .font(.footnote)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.15), value: facePresent)
    }
}

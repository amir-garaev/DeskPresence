import SwiftUI

// MARK: - SessionsOverlay

struct SessionsOverlay<Content: View>: View {
    // MARK: Props
    @Binding var isPresented: Bool
    @ViewBuilder var content: () -> Content

    // MARK: Body
    var body: some View {
        Group {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { isPresented = false }

                    content()
                        .frame(width: 560, height: 380)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(nsColor: .windowBackgroundColor))
                                .shadow(radius: 20)
                        )
                        .onExitCommand { isPresented = false }
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.2), value: isPresented)
                .zIndex(1)
            }
        }
    }
}

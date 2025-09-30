import SwiftUI

// MARK: - SessionNameRow

struct SessionNameRow: View {
    @Binding var name: String
    // MARK: Body
    var body: some View {
        HStack {
            Spacer(minLength: 0)
            TextField("Enter a name session", text: $name)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .frame(width: 260)
            Spacer(minLength: 0)
        }
    }
}

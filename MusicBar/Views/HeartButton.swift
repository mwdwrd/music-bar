import SwiftUI

struct HeartButton: View {
    @Binding var isFavorited: Bool
    var onToggle: () async -> Void

    @State private var isLoading = false
    @State private var pulse = false

    var body: some View {
        Button {
            guard !isLoading else { return }
            Task {
                isLoading = true
                await onToggle()
                isLoading = false

                // Quick pulse on toggle
                withAnimation(.easeOut(duration: 0.15)) { pulse = true }
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeIn(duration: 0.2)) { pulse = false }
            }
        } label: {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.system(size: 14))
                .foregroundStyle(isFavorited ? .pink : .secondary)
                .scaleEffect(pulse ? 1.25 : 1.0)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isLoading ? 0.5 : 1.0)
        .disabled(isLoading)
    }
}

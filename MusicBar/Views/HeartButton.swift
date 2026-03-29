import SwiftUI

struct HeartButton: View {
    @Binding var isFavorited: Bool
    var onToggle: () async -> Void

    @State private var isLoading = false
    @State private var showConfirmation = false

    var body: some View {
        Button {
            guard !isLoading else { return }
            Task {
                isLoading = true
                await onToggle()
                isLoading = false

                // Show confirmation briefly
                withAnimation(.easeInOut(duration: 0.3)) {
                    showConfirmation = true
                }
                try? await Task.sleep(for: .seconds(1.2))
                withAnimation(.easeInOut(duration: 0.3)) {
                    showConfirmation = false
                }
            }
        } label: {
            ZStack {
                Image(systemName: isFavorited ? "heart.fill" : "heart")
                    .font(.title2)
                    .foregroundStyle(isFavorited ? .pink : .primary)
                    .scaleEffect(showConfirmation ? 1.3 : 1.0)
                    .animation(.bouncy(duration: 0.4), value: isFavorited)

                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                }
            }
        }
        .buttonStyle(.glass)
        .disabled(isLoading)
    }
}

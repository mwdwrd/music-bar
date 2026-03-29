import SwiftUI
import PhosphorSwift

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

                withAnimation(.easeOut(duration: 0.12)) { pulse = true }
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeIn(duration: 0.2)) { pulse = false }
            }
        } label: {
            (isFavorited ? Ph.heart.fill : Ph.heart.bold)
                .renderingMode(.template)
                .foregroundStyle(isFavorited ? .pink : .white)
                .frame(width: 20, height: 20)
                .scaleEffect(pulse ? 1.15 : 1.0)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.glass)
        .opacity(isLoading ? 0.5 : 1.0)
        .disabled(isLoading)
    }
}

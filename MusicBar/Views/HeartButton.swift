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

                withAnimation(.easeOut(duration: 0.12)) { pulse = true }
                try? await Task.sleep(for: .milliseconds(120))
                withAnimation(.easeIn(duration: 0.2)) { pulse = false }
            }
        } label: {
            Image(systemName: isFavorited ? "heart.fill" : "heart")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(isFavorited ? .pink : .primary)
                .scaleEffect(pulse ? 1.2 : 1.0)
                .frame(width: 60, height: 60)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 14))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(isLoading ? 0.5 : 1.0)
        .disabled(isLoading)
    }
}

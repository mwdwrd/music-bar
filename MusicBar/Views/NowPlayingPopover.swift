import SwiftUI

struct NowPlayingPopover: View {
    let nowPlaying: NowPlayingModel

    var body: some View {
        VStack(spacing: 12) {
            Text(nowPlaying.title ?? "Not Playing")
                .font(.headline)
            Text(nowPlaying.artistName ?? "")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 280)
    }
}

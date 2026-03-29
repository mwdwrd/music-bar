import SwiftUI

struct NowPlayingPopover: View {
    let nowPlaying: NowPlayingModel

    var body: some View {
        VStack(spacing: 16) {
            if nowPlaying.hasTrack {
                trackInfo
            } else {
                emptyState
            }
        }
        .padding(20)
        .frame(width: 300)
    }

    private var trackInfo: some View {
        VStack(spacing: 16) {
            // Album art
            artworkView

            // Track details
            VStack(spacing: 4) {
                Text(nowPlaying.title ?? "")
                    .font(.headline)
                    .lineLimit(1)

                Text(nowPlaying.artistName ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let album = nowPlaying.albumName {
                    Text(album)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }

            // Action buttons (placeholder — wired in Units 5 & 6)
            actionButtons
        }
    }

    private var artworkView: some View {
        Group {
            if let url = nowPlaying.albumArtworkURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    artworkPlaceholder
                }
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 8, y: 4)
    }

    private var artworkPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.quaternary)
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: 40))
                    .foregroundStyle(.tertiary)
            }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            // Heart button placeholder
            Button {
                // Wired in Unit 5
            } label: {
                Image(systemName: nowPlaying.isFavorited ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(nowPlaying.isFavorited ? .pink : .primary)
            }
            .buttonStyle(.glass)

            // Playlist button placeholder
            Button {
                // Wired in Unit 6
            } label: {
                Label("Add to Playlist", systemImage: "text.badge.plus")
                    .font(.title3)
            }
            .buttonStyle(.glass)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note")
                .font(.system(size: 32))
                .foregroundStyle(.tertiary)
            Text("Nothing playing")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Play something in Music to get started")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 20)
    }
}

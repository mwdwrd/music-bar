import SwiftUI

struct NowPlayingPopover: View {
    @Bindable var nowPlaying: NowPlayingModel
    @Bindable var playlistManager: PlaylistManager
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if nowPlaying.hasTrack {
                trackInfo
                    .padding(20)
            } else {
                emptyState
                    .padding(20)
            }

            Divider()

            HStack {
                Button("Settings") { onOpenSettings() }
                Spacer()
                Button("Quit") { onQuit() }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .frame(width: 300)
        .overlay(alignment: .bottom) {
            confirmationOverlay
        }
    }

    private var trackInfo: some View {
        VStack(spacing: 16) {
            artworkView

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
            HeartButton(isFavorited: $nowPlaying.isFavorited) {
                do {
                    let newState = !nowPlaying.isFavorited
                    try await AppleScriptBridge.shared.setFavorited(newState)
                    await MainActor.run {
                        nowPlaying.isFavorited = newState
                    }
                } catch {
                    // Revert on failure
                }
            }

            if let title = nowPlaying.title, let artist = nowPlaying.artistName {
                PlaylistPicker(
                    trackName: title,
                    artistName: artist,
                    playlistManager: playlistManager
                )
            }
        }
    }

    @ViewBuilder
    private var confirmationOverlay: some View {
        if let message = playlistManager.confirmationMessage {
            Text(message)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 40)
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

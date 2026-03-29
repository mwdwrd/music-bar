import SwiftUI

struct NowPlayingPopover: View {
    @Bindable var nowPlaying: NowPlayingModel
    @Bindable var playlistManager: PlaylistManager
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @State private var showTrackInfo = false
    @State private var toastMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            if nowPlaying.hasTrack {
                iconRow
                    .padding(12)

                if showTrackInfo {
                    trackInfoPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                emptyState
                    .padding(16)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showTrackInfo)
        .overlay(alignment: .bottom) {
            toast
        }
        .onChange(of: nowPlaying.title) {
            showTrackInfo = false
        }
    }

    // MARK: - Three Icons

    private var iconRow: some View {
        HStack(spacing: 10) {
            // 1. Artwork — tap to reveal who's playing
            artworkButton

            // 2. Heart — tap to toggle love
            heartIcon

            // 3. Plus — tap to add, hold for playlist picker
            plusIcon
        }
    }

    // MARK: - Artwork Button

    private var artworkButton: some View {
        Button {
            withAnimation { showTrackInfo.toggle() }
        } label: {
            Group {
                if let image = nowPlaying.artworkImage {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(.fill.tertiary)
                        Image(systemName: "music.note")
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Heart

    private var heartIcon: some View {
        HeartButton(isFavorited: $nowPlaying.isFavorited) {
            do {
                let newState = !nowPlaying.isFavorited
                try await AppleScriptBridge.shared.setFavorited(newState)
                await MainActor.run {
                    nowPlaying.isFavorited = newState
                }
            } catch {}
        }
    }

    // MARK: - Plus (tap = add, hold = pick playlist)

    private var plusIcon: some View {
        Menu {
            ForEach(playlistManager.playlists, id: \.self) { playlist in
                Button(playlist) {
                    addToPlaylist(playlist)
                }
            }
            if playlistManager.playlists.isEmpty {
                Text("No playlists found")
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(.primary)
                .frame(width: 60, height: 60)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 14))
        } primaryAction: {
            if let playlist = playlistManager.lastUsedPlaylist {
                addToPlaylist(playlist)
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    private func addToPlaylist(_ name: String) {
        guard let title = nowPlaying.title,
              let artist = nowPlaying.artistName else { return }
        Task {
            let success = await playlistManager.addToPlaylist(
                name, trackName: title, artistName: artist
            )
            if success {
                showToast("Added to \(name)")
            }
        }
    }

    // MARK: - Track Info Panel

    private var trackInfoPanel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(nowPlaying.title ?? "")
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
            Text(nowPlaying.artistName ?? "")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if let album = nowPlaying.albumName {
                Text(album)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Toast

    @ViewBuilder
    private var toast: some View {
        if let message = toastMessage {
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 4)
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.15)) { toastMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            withAnimation(.easeIn(duration: 0.3)) { toastMessage = nil }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.fill.tertiary)
                Image(systemName: "music.note")
                    .font(.system(size: 22, weight: .light))
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 60, height: 60)

            VStack(alignment: .leading, spacing: 2) {
                Text("Nothing playing")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Play something in Music")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

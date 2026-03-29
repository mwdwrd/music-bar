import SwiftUI
import PhosphorSwift

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
            artworkButton
            heartIcon
            plusButton
        }
    }

    // MARK: - 1. Artwork

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
                        Ph.musicNote.bold
                            .color(.secondary)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. Heart

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

    // MARK: - 3. Plus

    private var plusButton: some View {
        Button {
            if let playlist = playlistManager.lastUsedPlaylist {
                addToPlaylist(playlist)
            }
        } label: {
            Ph.plus.bold
                .color(.primary)
                .frame(width: 28, height: 28)
                .frame(width: 60, height: 60)
                .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 14))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            ForEach(playlistManager.playlists, id: \.self) { playlist in
                Button(playlist) {
                    addToPlaylist(playlist)
                }
            }
            if playlistManager.playlists.isEmpty {
                Text("No playlists found")
            }

            Divider()

            Button("Settings...") { onOpenSettings() }
            Button("Quit Music Bar") { onQuit() }
        }
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
            HStack(spacing: 6) {
                if nowPlaying.isPlaying {
                    PlaybackIndicator()
                }
                Text(nowPlaying.title ?? "")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
            }
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
                Ph.musicNote.bold
                    .color(.gray)
                    .frame(width: 24, height: 24)
                    .opacity(0.5)
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

// MARK: - Playback Indicator

struct PlaybackIndicator: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 1.5) {
            ForEach(0..<3, id: \.self) { i in
                RoundedRectangle(cornerRadius: 0.5)
                    .fill(.pink)
                    .frame(width: 2, height: animate ? heights[i] : 3)
                    .animation(
                        .easeInOut(duration: durations[i])
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.1),
                        value: animate
                    )
            }
        }
        .frame(width: 10, height: 10)
        .onAppear { animate = true }
    }

    private let heights: [CGFloat] = [8, 10, 6]
    private let durations: [Double] = [0.4, 0.5, 0.35]
}

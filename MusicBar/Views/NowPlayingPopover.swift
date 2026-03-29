import SwiftUI
import PhosphorSwift

struct NowPlayingPopover: View {
    @Bindable var nowPlaying: NowPlayingModel
    @Bindable var playlistManager: PlaylistManager
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    @State private var showTrackInfo = false

    var body: some View {
        VStack(spacing: 0) {
            if nowPlaying.hasTrack {
                iconRow
                    .padding(10)

                if showTrackInfo {
                    trackInfoPanel
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            } else {
                emptyState
                    .padding(14)
            }
        }
        .animation(.easeOut(duration: 0.2), value: showTrackInfo)
        .onChange(of: nowPlaying.trackDidChange) {
            if nowPlaying.trackDidChange {
                showTrackInfo = false
                Task { await playlistManager.checkMembership() }
                nowPlaying.trackDidChange = false
            }
        }
        .contextMenu {
            Button("Settings...") { onOpenSettings() }
            Button("Quit Music Bar") { onQuit() }
        }
    }

    // MARK: - Three Icons

    private var iconRow: some View {
        HStack(spacing: 8) {
            artworkButton
            heartButton
            playlistButton
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
                        Color.clear
                        Ph.musicNote.bold
                            .renderingMode(.template)
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 20)
                    }
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.glass)
    }

    // MARK: - 2. Heart

    private var heartButton: some View {
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

    // MARK: - 3. Playlist Toggle

    private var playlistButton: some View {
        PlaylistToggle(
            isInPlaylist: playlistManager.isInTargetPlaylist,
            isConfigured: playlistManager.targetPlaylist != nil,
            isLoading: playlistManager.isLoading,
            onToggle: { Task { await playlistManager.toggle() } },
            onOpenSettings: onOpenSettings
        )
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
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 8) {
            ZStack {
                Color.clear
                Ph.musicNote.bold
                    .renderingMode(.template)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            .frame(width: 44, height: 44)

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

// MARK: - Playlist Toggle Button

struct PlaylistToggle: View {
    let isInPlaylist: Bool
    let isConfigured: Bool
    let isLoading: Bool
    var onToggle: () -> Void
    var onOpenSettings: () -> Void

    @State private var pulse = false

    var body: some View {
        Button {
            if isConfigured {
                onToggle()
                withAnimation(.easeOut(duration: 0.12)) { pulse = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(120))
                    await MainActor.run {
                        withAnimation(.easeIn(duration: 0.2)) { pulse = false }
                    }
                }
            } else {
                onOpenSettings()
            }
        } label: {
            (isInPlaylist ? Ph.check.bold : Ph.plus.bold)
                .renderingMode(.template)
                .foregroundStyle(isInPlaylist ? .green : .white)
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

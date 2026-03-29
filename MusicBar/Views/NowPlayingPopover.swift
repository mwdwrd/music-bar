import SwiftUI

struct NowPlayingPopover: View {
    @Bindable var nowPlaying: NowPlayingModel
    @Bindable var playlistManager: PlaylistManager
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if nowPlaying.hasTrack {
                trackContent
            } else {
                emptyState
            }
        }
        .frame(width: 280)
        .overlay(alignment: .bottom) {
            confirmationToast
        }
    }

    // MARK: - Track Content

    private var trackContent: some View {
        VStack(spacing: 0) {
            // Artwork — the visual anchor
            artworkView
                .padding(.horizontal, 20)
                .padding(.top, 20)

            // Track info + actions
            VStack(spacing: 14) {
                trackMeta
                actionRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 16)

            // Footer
            footerBar
        }
    }

    private var artworkView: some View {
        Group {
            if let image = nowPlaying.artworkImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                artworkPlaceholder
            }
        }
        .frame(width: 240, height: 240)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var artworkPlaceholder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(.fill.tertiary)

            Image(systemName: "music.note")
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Track Metadata

    private var trackMeta: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    if nowPlaying.isPlaying {
                        PlaybackIndicator()
                    }
                    Text(nowPlaying.title ?? "")
                        .font(.system(size: 13, weight: .semibold))
                        .lineLimit(1)
                }

                Text(nowPlaying.artistName ?? "")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Actions

    private var actionRow: some View {
        HStack(spacing: 8) {
            HeartButton(isFavorited: $nowPlaying.isFavorited) {
                do {
                    let newState = !nowPlaying.isFavorited
                    try await AppleScriptBridge.shared.setFavorited(newState)
                    await MainActor.run {
                        nowPlaying.isFavorited = newState
                    }
                } catch {}
            }

            if let title = nowPlaying.title, let artist = nowPlaying.artistName {
                PlaylistPicker(
                    trackName: title,
                    artistName: artist,
                    playlistManager: playlistManager
                )
            }

            Spacer()
        }
    }

    // MARK: - Footer

    private var footerBar: some View {
        HStack(spacing: 0) {
            Button { onOpenSettings() } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
            .buttonStyle(.plain)

            Spacer()

            Button("Quit", action: onQuit)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Confirmation Toast

    @ViewBuilder
    private var confirmationToast: some View {
        if let message = playlistManager.confirmationMessage {
            Text(message)
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(.ultraThinMaterial, in: Capsule())
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 36)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Image(systemName: "music.note")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.tertiary)

                VStack(spacing: 4) {
                    Text("Nothing playing")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Play a track in Music to get started.")
                        .font(.system(size: 11))
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
            .padding(.horizontal, 20)

            footerBar
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

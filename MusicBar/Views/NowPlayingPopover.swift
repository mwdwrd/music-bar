import SwiftUI
import PhosphorSwift

private let iconSize: CGFloat = 44
private let iconSpacing: CGFloat = 8
// 4 icons + 3 gaps
private let rowWidth: CGFloat = iconSize * 4 + iconSpacing * 3

struct NowPlayingPopover: View {
    @Bindable var nowPlaying: NowPlayingModel
    @Bindable var playlistManager: PlaylistManager
    var onOpenSettings: () -> Void
    var onQuit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if nowPlaying.hasTrack {
                iconRow
                    .padding(10)
                trackInfoPanel
            } else {
                emptyState
                    .padding(14)
            }
        }
        .onChange(of: nowPlaying.trackDidChange) {
            if nowPlaying.trackDidChange {
                Task { await playlistManager.checkMembership() }
                nowPlaying.trackDidChange = false
            }
        }
        .contextMenu {
            Button("Quit Music Bar") { onQuit() }
        }
    }

    // MARK: - Four Icons

    private var iconRow: some View {
        HStack(spacing: iconSpacing) {
            artworkIcon
            heartButton
            playlistButton
            settingsButton
        }
    }

    // MARK: - 1. Artwork (tap to play/pause)

    @State private var artworkHovered = false

    private var artworkIcon: some View {
        Button {
            Task {
                try? await AppleScriptBridge.shared.playPause()
            }
        } label: {
            ZStack {
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

                // Play/pause overlay on hover
                if artworkHovered {
                    Color.black.opacity(0.45)
                    (nowPlaying.isPlaying ? Ph.pause.fill : Ph.play.fill)
                        .renderingMode(.template)
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                }
            }
            .frame(width: iconSize, height: iconSize)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                artworkHovered = hovering
            }
        }
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
            onToggle: { Task { await playlistManager.toggle() } }
        )
    }

    // MARK: - 4. Settings

    private var settingsButton: some View {
        Button { onOpenSettings() } label: {
            Ph.gearSix.bold
                .renderingMode(.template)
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .frame(width: iconSize, height: iconSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Track Info

    private var trackInfoPanel: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if nowPlaying.isPlaying {
                    PlaybackIndicator()
                }
                MarqueeText(
                    text: nowPlaying.title ?? "",
                    font: .system(size: 12, weight: .medium)
                )
            }
            HStack(spacing: 0) {
                Text(nowPlaying.artistName ?? "")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Spacer()
                skipNextButton
            }
        }
        .frame(width: rowWidth, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.bottom, 10)
    }

    // MARK: - Skip Next

    @State private var skipPulse = false

    private var skipNextButton: some View {
        Button {
            Task {
                try? await AppleScriptBridge.shared.nextTrack()
            }
            withAnimation(.easeOut(duration: 0.1)) { skipPulse = true }
            Task {
                try? await Task.sleep(for: .milliseconds(100))
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.15)) { skipPulse = false }
                }
            }
        } label: {
            Ph.skipForward.fill
                .renderingMode(.template)
                .foregroundStyle(.secondary)
                .frame(width: 12, height: 12)
                .scaleEffect(skipPulse ? 1.2 : 1.0)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: iconSpacing) {
            ZStack {
                Color.clear
                Ph.musicNote.bold
                    .renderingMode(.template)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, height: 20)
            }
            .frame(width: iconSize, height: iconSize)

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

// MARK: - Marquee Text

struct MarqueeText: View {
    let text: String
    let font: Font

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var animating = false

    private var needsScroll: Bool { textWidth > containerWidth }

    var body: some View {
        GeometryReader { geo in
            let cw = geo.size.width
            Text(text)
                .font(font)
                .lineLimit(1)
                .fixedSize()
                .background(GeometryReader { textGeo in
                    Color.clear.onAppear {
                        textWidth = textGeo.size.width
                        containerWidth = cw
                        startScrollIfNeeded()
                    }
                })
                .offset(x: needsScroll ? offset : 0)
                .onChange(of: text) {
                    offset = 0
                    animating = false
                    textWidth = 0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        startScrollIfNeeded()
                    }
                }
        }
        .frame(height: 16)
        .clipped()
    }

    private func startScrollIfNeeded() {
        guard needsScroll, !animating else { return }
        animating = true
        let scrollDistance = textWidth - containerWidth + 20
        let duration = Double(scrollDistance) / 30.0

        Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard animating else { return }
            withAnimation(.linear(duration: duration)) {
                offset = -scrollDistance
            }
            try? await Task.sleep(for: .seconds(duration + 1.5))
            guard animating else { return }
            withAnimation(.linear(duration: 0.4)) {
                offset = 0
            }
            try? await Task.sleep(for: .seconds(0.5))
            animating = false
            startScrollIfNeeded()
        }
    }
}

// MARK: - Playlist Toggle Button

struct PlaylistToggle: View {
    let isInPlaylist: Bool
    let isConfigured: Bool
    let isLoading: Bool
    var onToggle: () -> Void

    @State private var pulse = false

    var body: some View {
        Button {
            guard isConfigured else { return }
            onToggle()
            withAnimation(.easeOut(duration: 0.12)) { pulse = true }
            Task {
                try? await Task.sleep(for: .milliseconds(120))
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.2)) { pulse = false }
                }
            }
        } label: {
            (isInPlaylist ? Ph.check.bold : Ph.plus.bold)
                .renderingMode(.template)
                .foregroundStyle(isInPlaylist ? .green : .white)
                .frame(width: 20, height: 20)
                .scaleEffect(pulse ? 1.15 : 1.0)
                .frame(width: iconSize, height: iconSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 10))
        .opacity(!isConfigured || isLoading ? 0.3 : 1.0)
        .disabled(!isConfigured || isLoading)
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

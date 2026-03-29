import SwiftUI
import MusicKit
import KeyboardShortcuts

@main
struct MusicBarApp: App {
    @State private var nowPlaying = NowPlayingModel()
    @State private var playlistManager = PlaylistManager()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        MenuBarExtra {
            NowPlayingPopover(
                nowPlaying: nowPlaying,
                playlistManager: playlistManager,
                onOpenSettings: {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                },
                onQuit: { NSApplication.shared.terminate(nil) }
            )
        } label: {
            Label {
                Text(nowPlaying.title ?? "Not Playing")
            } icon: {
                Image(systemName: "music.note")
                    .renderingMode(.template)
            }
        }
        .menuBarExtraStyle(.window)

        Window("Music Bar Settings", id: "settings") {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }

    init() {
        Task {
            let status = await MusicAuthorization.request()
            if status != .authorized {
                print("MusicKit authorization denied: \(status)")
            }
        }

        setupGlobalShortcuts()
    }

    private func setupGlobalShortcuts() {
        KeyboardShortcuts.onKeyUp(for: .toggleLove) { [self] in
            Task { @MainActor in
                guard nowPlaying.hasTrack else { return }
                let newState = !nowPlaying.isFavorited
                do {
                    try await AppleScriptBridge.shared.setFavorited(newState)
                    nowPlaying.isFavorited = newState
                } catch {}
            }
        }

        KeyboardShortcuts.onKeyUp(for: .addToLastPlaylist) { [self] in
            Task { @MainActor in
                guard nowPlaying.hasTrack else { return }
                await playlistManager.toggle()
            }
        }
    }
}

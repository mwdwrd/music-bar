import SwiftUI
import MusicKit
import KeyboardShortcuts

@main
struct MusicBarApp: App {
    @State private var nowPlaying = NowPlayingModel()
    @State private var playlistManager = PlaylistManager()

    var body: some Scene {
        MenuBarExtra {
            NowPlayingPopover(
                nowPlaying: nowPlaying,
                playlistManager: playlistManager,
                onOpenSettings: openSettings,
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

        Settings {
            SettingsView()
        }
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
                } catch {
                    // Silent failure for keyboard shortcuts
                }
            }
        }

        KeyboardShortcuts.onKeyUp(for: .addToLastPlaylist) { [self] in
            Task { @MainActor in
                guard let title = nowPlaying.title,
                      let artist = nowPlaying.artistName,
                      let playlist = playlistManager.lastUsedPlaylist else { return }
                await playlistManager.addToPlaylist(
                    playlist,
                    trackName: title,
                    artistName: artist
                )
            }
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}

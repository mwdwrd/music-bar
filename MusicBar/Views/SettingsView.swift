import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    @State private var playlists: [String] = []
    @AppStorage("targetPlaylist") private var targetPlaylist: String = ""
    @State private var isLoadingPlaylists = true

    var body: some View {
        Form {
            Section("Playlist") {
                if isLoadingPlaylists {
                    ProgressView("Loading playlists...")
                } else if playlists.isEmpty {
                    Text("No playlists found. Make sure Music is running.")
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Add songs to:", selection: $targetPlaylist) {
                        Text("Choose a playlist...").tag("")
                        ForEach(playlists, id: \.self) { name in
                            Text(name).tag(name)
                        }
                    }
                }

                Button("Refresh Playlists") {
                    Task { await loadPlaylists() }
                }
                .font(.caption)
            }

            Section("Keyboard Shortcuts") {
                KeyboardShortcuts.Recorder("Love / Unlove:", name: .toggleLove)
                KeyboardShortcuts.Recorder("Add to Playlist:", name: .addToLastPlaylist)
            }
        }
        .formStyle(.grouped)
        .frame(width: 360, height: 260)
        .task { await loadPlaylists() }
    }

    private func loadPlaylists() async {
        isLoadingPlaylists = true
        do {
            playlists = try await AppleScriptBridge.shared.getPlaylistNames()
        } catch {}
        isLoadingPlaylists = false
    }
}

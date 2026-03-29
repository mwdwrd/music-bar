import SwiftUI

struct PlaylistPicker: View {
    let trackName: String
    let artistName: String
    @Bindable var playlistManager: PlaylistManager

    var body: some View {
        HStack(spacing: 8) {
            // Primary button: add to last-used playlist
            if let lastUsed = playlistManager.lastUsedPlaylist {
                Button {
                    Task {
                        await playlistManager.addToPlaylist(
                            lastUsed,
                            trackName: trackName,
                            artistName: artistName
                        )
                    }
                } label: {
                    Label(lastUsed, systemImage: "plus")
                        .lineLimit(1)
                        .font(.caption)
                }
                .buttonStyle(.glass)
                .disabled(playlistManager.isLoading)
            }

            // Dropdown for all playlists
            Menu {
                ForEach(playlistManager.playlists, id: \.self) { playlist in
                    Button(playlist) {
                        Task {
                            await playlistManager.addToPlaylist(
                                playlist,
                                trackName: trackName,
                                artistName: artistName
                            )
                        }
                    }
                }

                if playlistManager.playlists.isEmpty {
                    Text("No playlists found")
                }
            } label: {
                Image(systemName: "text.badge.plus")
                    .font(.title2)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

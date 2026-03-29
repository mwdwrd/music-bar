import SwiftUI

struct PlaylistPicker: View {
    let trackName: String
    let artistName: String
    @Bindable var playlistManager: PlaylistManager

    var body: some View {
        HStack(spacing: 4) {
            // One-click: add to last-used playlist
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
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                        Text(lastUsed)
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(.fill.quaternary, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(playlistManager.isLoading)
            }

            // Full playlist menu
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
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 20, height: 20)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
    }
}

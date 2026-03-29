import Foundation
import Observation

@MainActor
@Observable
final class PlaylistManager {
    var playlists: [String] = []
    var lastUsedPlaylist: String? {
        didSet {
            if let lastUsedPlaylist {
                UserDefaults.standard.set(lastUsedPlaylist, forKey: "lastUsedPlaylist")
            }
        }
    }
    var isLoading = false
    var confirmationMessage: String?

    init() {
        lastUsedPlaylist = UserDefaults.standard.string(forKey: "lastUsedPlaylist")
        Task { await refreshPlaylists() }
    }

    func refreshPlaylists() async {
        do {
            let names = try await AppleScriptBridge.shared.getPlaylistNames()
            self.playlists = names
        } catch {
            // Non-critical — user can retry
        }
    }

    func addToPlaylist(_ playlistName: String, trackName: String, artistName: String) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppleScriptBridge.shared.addCurrentTrackToPlaylist(playlistName)
            lastUsedPlaylist = playlistName
            showConfirmation("Added to \(playlistName)")
            return true
        } catch {
            showConfirmation("Failed to add")
            return false
        }
    }

    private func showConfirmation(_ message: String) {
        confirmationMessage = message
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            confirmationMessage = nil
        }
    }
}

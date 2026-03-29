import Foundation
import Observation

@MainActor
@Observable
final class PlaylistManager {
    var playlists: [String] = []
    var isInTargetPlaylist: Bool = false
    var isLoading = false

    var targetPlaylist: String? {
        didSet {
            if let targetPlaylist {
                UserDefaults.standard.set(targetPlaylist, forKey: "targetPlaylist")
            }
        }
    }

    init() {
        targetPlaylist = UserDefaults.standard.string(forKey: "targetPlaylist")
        Task { await refreshPlaylists() }
    }

    func refreshPlaylists() async {
        do {
            let names = try await AppleScriptBridge.shared.getPlaylistNames()
            self.playlists = names
        } catch {}
    }

    /// Check if the current track is already in the target playlist.
    func checkMembership() async {
        guard let playlist = targetPlaylist else {
            isInTargetPlaylist = false
            return
        }
        do {
            let result = try await AppleScriptBridge.shared.isCurrentTrackInPlaylist(playlist)
            self.isInTargetPlaylist = result
        } catch {
            self.isInTargetPlaylist = false
        }
    }

    /// Toggle: add if not in playlist, remove if already in.
    func toggle() async {
        guard let playlist = targetPlaylist else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            if isInTargetPlaylist {
                try await AppleScriptBridge.shared.removeCurrentTrackFromPlaylist(playlist)
                isInTargetPlaylist = false
            } else {
                try await AppleScriptBridge.shared.addCurrentTrackToPlaylist(playlist)
                isInTargetPlaylist = true
            }
        } catch {}
    }
}

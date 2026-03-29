import Foundation
import MusicKit
import Observation

@MainActor
@Observable
final class NowPlayingModel {
    var title: String?
    var artistName: String?
    var albumName: String?
    var albumArtworkURL: URL?
    var isFavorited: Bool = false
    var isPlaying: Bool = false
    var hasTrack: Bool { title != nil }

    private var pollTask: Task<Void, Never>?
    private var lastTrackKey: String?

    init() {
        startPolling()
    }

    func stop() {
        pollTask?.cancel()
    }

    private func startPolling() {
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(2))
            }
        }
    }

    private func refresh() async {
        do {
            let state = try await AppleScriptBridge.shared.getPlayerState()
            let track = try await AppleScriptBridge.shared.getCurrentTrack()

            self.isPlaying = state == .playing

            guard let track else {
                self.title = nil
                self.artistName = nil
                self.albumName = nil
                self.albumArtworkURL = nil
                self.isFavorited = false
                self.lastTrackKey = nil
                return
            }

            self.title = track.name
            self.artistName = track.artist
            self.albumName = track.album
            self.isFavorited = track.isFavorited

            // Only fetch artwork when track changes
            let newKey = "\(track.name)—\(track.artist)"
            if newKey != self.lastTrackKey {
                self.lastTrackKey = newKey
                await fetchArtwork(title: track.name, artist: track.artist)
            }
        } catch {
            self.isPlaying = false
        }
    }

    private func fetchArtwork(title: String, artist: String) async {
        do {
            var request = MusicCatalogSearchRequest(term: "\(title) \(artist)", types: [Song.self])
            request.limit = 1
            let response = try await request.response()
            if let song = response.songs.first,
               let url = song.artwork?.url(width: 200, height: 200) {
                self.albumArtworkURL = url
            }
        } catch {
            // Artwork lookup is non-critical
        }
    }
}

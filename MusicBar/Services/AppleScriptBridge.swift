import Foundation
import AppKit

/// Communicates with the Music app via AppleScript.
/// This is necessary because MusicKit's write APIs (love, add to playlist)
/// and SystemMusicPlayer are unavailable on macOS.
actor AppleScriptBridge {
    static let shared = AppleScriptBridge()

    struct TrackInfo: Equatable, Sendable {
        let name: String
        let artist: String
        let album: String
        let isFavorited: Bool
    }

    enum PlayerState: String, Sendable {
        case playing, paused, stopped, unknown
    }

    enum BridgeError: Error, LocalizedError {
        case musicAppNotRunning
        case noTrackPlaying
        case scriptFailed(String)
        case trackNotFound

        var errorDescription: String? {
            switch self {
            case .musicAppNotRunning: "Music app is not running"
            case .noTrackPlaying: "No track is currently playing"
            case .scriptFailed(let msg): "AppleScript error: \(msg)"
            case .trackNotFound: "Track not found"
            }
        }
    }

    // MARK: - Read Operations

    func getPlayerState() throws -> PlayerState {
        guard isMusicRunning() else { return .stopped }
        let result = try runScript("tell application \"Music\" to get player state as string")
        switch result.lowercased() {
        case "playing": return .playing
        case "paused": return .paused
        case "stopped": return .stopped
        default: return .unknown
        }
    }

    func getCurrentTrack() throws -> TrackInfo? {
        guard isMusicRunning() else { return nil }

        let state = try getPlayerState()
        guard state == .playing || state == .paused else { return nil }

        let name = try runScript("tell application \"Music\" to get name of current track")
        let artist = try runScript("tell application \"Music\" to get artist of current track")
        let album = try runScript("tell application \"Music\" to get album of current track")
        let favResult = try runScript("tell application \"Music\" to get favorited of current track")
        let isFavorited = favResult.lowercased() == "true"

        return TrackInfo(name: name, artist: artist, album: album, isFavorited: isFavorited)
    }

    func getArtworkData() throws -> Data? {
        guard isMusicRunning() else { return nil }
        let script = """
        tell application "Music"
            try
                set artData to raw data of artwork 1 of current track
                return artData
            on error
                return ""
            end try
        end tell
        """
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        let result = appleScript.executeAndReturnError(&error)
        if error != nil { return nil }
        // The result comes back as NSAppleEventDescriptor with raw data
        return result.data
    }

    // MARK: - Write Operations

    func setFavorited(_ favorited: Bool) throws {
        guard isMusicRunning() else { throw BridgeError.musicAppNotRunning }
        let value = favorited ? "true" : "false"
        try runScript("tell application \"Music\" to set favorited of current track to \(value)")
    }

    func addCurrentTrackToPlaylist(_ playlistName: String) throws {
        guard isMusicRunning() else { throw BridgeError.musicAppNotRunning }
        // Escape quotes in playlist name
        let escaped = playlistName.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Music"
            set theTrack to current track
            set thePlaylist to playlist "\(escaped)"
            duplicate theTrack to thePlaylist
        end tell
        """
        try runScript(script)
    }

    func getPlaylistNames() throws -> [String] {
        guard isMusicRunning() else { return [] }
        let script = """
        tell application "Music"
            set playlistNames to {}
            repeat with p in (get every user playlist)
                set end of playlistNames to name of p
            end repeat
            set AppleScript's text item delimiters to "|||"
            return playlistNames as text
        end tell
        """
        let result = try runScript(script)
        guard !result.isEmpty else { return [] }
        return result.components(separatedBy: "|||")
    }

    // MARK: - Helpers

    private func isMusicRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == "com.apple.Music"
        }
    }

    @discardableResult
    private func runScript(_ source: String) throws -> String {
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw BridgeError.scriptFailed("Could not create script")
        }
        let result = script.executeAndReturnError(&error)
        if let error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            throw BridgeError.scriptFailed(message)
        }
        return result.stringValue ?? ""
    }
}

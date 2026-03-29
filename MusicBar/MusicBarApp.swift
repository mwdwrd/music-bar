import SwiftUI
import MusicKit

@main
struct MusicBarApp: App {
    @State private var nowPlaying = NowPlayingModel()

    var body: some Scene {
        MenuBarExtra {
            NowPlayingPopover(nowPlaying: nowPlaying)
        } label: {
            Label {
                Text(nowPlaying.title ?? "Not Playing")
            } icon: {
                Image(systemName: "music.note")
                    .renderingMode(.template)
            }
        }
        .menuBarExtraStyle(.window)
    }

    init() {
        Task {
            let status = await MusicAuthorization.request()
            if status != .authorized {
                print("MusicKit authorization denied: \(status)")
            }
        }
    }
}

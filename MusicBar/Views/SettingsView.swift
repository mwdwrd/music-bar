import SwiftUI
import KeyboardShortcuts

struct SettingsView: View {
    var body: some View {
        Form {
            Section("Keyboard Shortcuts") {
                KeyboardShortcuts.Recorder("Love / Unlove:", name: .toggleLove)
                KeyboardShortcuts.Recorder("Add to Playlist:", name: .addToLastPlaylist)
            }
        }
        .formStyle(.grouped)
        .frame(width: 350)
        .padding()
    }
}

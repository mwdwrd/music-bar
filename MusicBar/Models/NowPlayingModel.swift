import Foundation
import MusicKit
import Observation

@Observable
final class NowPlayingModel {
    var title: String?
    var artistName: String?
    var isPlaying: Bool = false

    init() {}
}

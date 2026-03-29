import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleLove = Self("toggleLove", default: .init(.l, modifiers: [.control, .option]))
    static let addToLastPlaylist = Self("addToLastPlaylist", default: .init(.p, modifiers: [.control, .option]))
}

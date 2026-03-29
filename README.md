# Music Bar

A tiny macOS menu bar app that makes it easy to heart songs and add them to playlists in Apple Music.

Apple Music's desktop UI requires too many clicks for the two most common mid-listen actions. Music Bar puts them one click away.

## What it does

Four icons live in your menu bar popover:

| Icon | Action |
|------|--------|
| Album art | Shows what's currently playing |
| Heart | Toggle love on the current track |
| Plus | Add/remove current track from your chosen playlist |
| Gear | Open settings |

- **Heart** and **Plus** are toggles — they show the current state and flip it on click
- **Plus** checks for duplicates — won't add a song that's already in the playlist
- Long song titles scroll like a ticker tape
- Global keyboard shortcuts: `⌃⌥L` to love, `⌃⌥P` to add to playlist (customizable in settings)

## Requirements

- macOS 26 (Tahoe) or later
- Apple Music with an active subscription
- Xcode 26+ to build from source

## Building

```bash
# Clone
git clone https://github.com/mwdwrd/music-bar.git
cd music-bar

# Generate Xcode project (requires xcodegen)
brew install xcodegen
xcodegen generate

# Build
xcodebuild -project MusicBar.xcodeproj -scheme MusicBar -destination 'platform=macOS' build
```

Or open `MusicBar.xcodeproj` in Xcode and hit Run.

## First launch

1. Music Bar will ask for Apple Music access — grant it
2. macOS will ask to allow automation of the Music app — grant it
3. Click the gear icon to pick which playlist the **+** button saves to
4. Optionally customize keyboard shortcuts in settings

## How it works

- **Now-playing detection**: Polls the Music app via AppleScript every 2 seconds (MusicKit's `SystemMusicPlayer` is unavailable on macOS)
- **Love + playlist actions**: Uses AppleScript to communicate with Music.app (MusicKit write APIs are also unavailable on macOS)
- **Album artwork**: Pulled directly from the Music app via AppleScript, with MusicKit catalog search as fallback
- **Global shortcuts**: [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) library (wraps Carbon hotkey APIs)
- **Icons**: [Phosphor Icons](https://phosphoricons.com) via [phosphor-icons/swift](https://github.com/phosphor-icons/swift)
- **Design**: macOS 26 Liquid Glass (`.glassEffect()`)

## Distribution

To distribute as a signed DMG:

1. Join the [Apple Developer Program](https://developer.apple.com/programs/)
2. Edit `scripts/build-dmg.sh` with your Team ID and Apple ID
3. Run `./scripts/build-dmg.sh`

## License

MIT

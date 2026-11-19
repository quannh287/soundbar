# SoundBar

A macOS menu bar mixer for Apple's built-in Background Sounds.

Layer any of the 16 sounds Apple ships with Accessibility > Audio > Background Sounds,
each with its own volume. Sounds the system has not downloaded yet are fetched from
Apple's MobileAsset catalog on first use.

![panel](docs/panel.png)

## Build

```sh
./build.sh      # -> SoundBar.app
./soundbar --list   # self-check: catalog parse + local asset lookup
```

Requires macOS 13+ and a Swift toolchain. No Xcode project, no dependencies.

## What it does

- **Mix** several sounds at once, per-sound volume plus a master.
- **Download on demand** from `mesu.apple.com`, reusing Apple's own copy under
  `/System/Library/AssetsV2` when the system already has it.
- **Shuffle**, because Apple ships each sound as interchangeable variations —
  looping one file has an audible seam.
- **Timer** to mute after 30 or 60 minutes.
- **Open at Login**, via `SMAppService`.
- Your mix persists and resumes on launch.

It plays the audio itself rather than driving Apple's ComfortSounds engine, so it is
independent of the System Settings toggle. The two do not stay in sync.

## Layout

Everything is in `main.swift`. Downloaded sounds land in
`~/Library/Application Support/SoundBar/`.

## Install

```sh
brew install quannh287/tap/soundbar
open "$(brew --prefix)/opt/soundbar/SoundBar.app"
```

Homebrew builds from source on your machine, so the ad-hoc signature is enough and
Gatekeeper never sees a quarantined download.

## License

MIT

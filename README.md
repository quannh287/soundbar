<img src="docs/icon.png" width="96" align="right">

# SoundBar

A macOS menu bar app that pins one window, dims everything else, and times how long
you actually stayed on it — with Apple's Background Sounds playing underneath.

![panel](docs/panel.png)

## Build

```sh
swift test          # pure logic: geometry, stats, nudge escalation
./build.sh          # -> SoundBar.app
./soundbar --list   # smoke check: catalog parse + local asset lookup (needs network)
```

Requires macOS 13+ and a Swift toolchain. A Swift package, no Xcode project,
no dependencies.

## Focus

Open the panel, pick a window from the list, pick a length, and start. Everything else on
every display dims or blurs; the pinned window stays sharp. The list starts on whatever
was frontmost when you opened the panel, so the common case is one click.

- **Pinned, not frontmost.** Every other app of this kind follows whichever window is
  active, which cannot tell reading a spec from reading Twitter. Pinning is what makes
  the timer and the warning mean anything.
- **The dimmed windows stay live.** The overlay ignores mouse events, so background
  work — a build, an agent session — is still readable and still clickable.
- **Add a second window** to keep something beside the pinned one, with no warning when
  you look at it.
- **Window titles are optional.** Without Screen Recording macOS withholds them, so the
  list falls back to app names, numbered when one app has several windows. Granting it
  turns those rows into real titles; nothing else changes.
- **A shake when you drift.** Stay on an unpinned window past the grace period and the
  cut-out shakes, then again every 15 seconds. The shake is a Core Animation keyframe,
  so the warning costs no CPU either.
- **Daily total**, seven-day strip, stored on your machine and nowhere else.

It needs no permissions. Window geometry comes from `CGWindowList`, which is not gated
by TCC — the Accessibility API would be, and macOS binds that grant to a code signature
that changes on every ad-hoc build.

### What it cannot do

- **Windows, not tabs.** Switching tabs inside the pinned window keeps working, because
  the window id does not change. Pinning one tab and dimming its siblings would need a
  browser extension.
- **Full-screen windows** live on their own Space, which the overlay deliberately does
  not join — joining it blacks the display out.
- **Screenshots and screen shares are dimmed too**, because the overlay takes part in
  screen capture. It has to: a DisplayLink monitor, which is what a dual-HDMI USB-C hub
  drives on Apple silicon, is painted from a capture of a virtual display, so a window
  that opts out of capture never appears on that screen at all.
- Minimising and closing the pinned window are indistinguishable without Accessibility;
  both fall back to dimming everything.

## Sounds

- **Mix** several sounds at once, per-sound volume plus a master.
- **Download on demand** from `mesu.apple.com`, reusing Apple's own copy under
  `/System/Library/AssetsV2` when the system already has it.
- **Shuffle**, because Apple ships each sound as interchangeable variations —
  looping one file has an audible seam.
- **Presets** — six built in (Deep Work, Cafe, Cozy, Sleep, Night, Flight), plus your own:
  save the current mix from the `+` chip; right-click one of yours to update it to the
  current mix, rename it, or delete it. Built-ins cannot be overwritten, only copied.
- **Animated menu bar icon** — equaliser bars while playing, run by Core Animation
  rather than a timer, so they cost no CPU.
- **Timer** to mute after 30 or 60 minutes, independent of the focus timer.
- **Open at Login**, via `SMAppService`.
- Your mix persists and resumes on launch.

It plays the audio itself rather than driving Apple's ComfortSounds engine, so it is
independent of the System Settings toggle. The two do not stay in sync.

## Cost

Measured with `top` and `footprint` on Apple silicon, three displays attached:

| | CPU | RAM |
|---|---|---|
| Idle, panel never opened | ~1.4% | 19 MB |
| After the panel has been opened once | ~1.3% | 46 MB |
| Focus session: three overlays, 30 Hz tracking | ~1–3% | +9 MB |
| Playing, three sounds | 1.2% (plus 2.0% coreaudiod) | 17 MB |

RAM is `phys_footprint`, which is what Activity Monitor shows; `ps` reports roughly twice
that because it counts shared framework pages.

The panel is built on first open rather than at launch: `sizingOptions` makes SwiftUI lay
the whole thing out to report a content size, and that one pass costs 26 MB that a menu
bar app nobody opened does not need to pay.

A focus session adds a 30 Hz poll, because reading another app's window geometry without
Accessibility means asking `CGWindowList` and nothing pushes. That timer exists only while
a session runs, and it is registered in the common run loop modes — scheduled in the
default mode it would stall for as long as AppKit tracks events, which includes the whole
time this app's own popover is open.

RAM is `phys_footprint`, which is what Activity Monitor shows; `ps` reports ~40 MB RSS
because it counts shared framework pages.

Reassigning the status item's image on a timer cost 2.5% of a core on its own — more than
decoding the audio — whether the frames were drawn live or prepared in advance. The bars
are `CALayer`s under a repeating `CABasicAnimation` instead, so the compositor runs them
and the app does nothing per frame.

## Layout

`Sources/FocusKit` holds everything — `Focus/` for the overlay, window tracking, nudge
and stats, `Sound/` for the mixer, `UI/` for the panel — and `Sources/focusbar` is the
entry point. `build.sh` wraps the built binary in `SoundBar.app`.

The icon is generated by `tools/makeicon.swift` — run it, pipe the PNG through
`sips`/`iconutil`, and commit the resulting `AppIcon.icns`. Downloaded sounds land in
`~/Library/Application Support/SoundBar/`.

## Install

```sh
brew install quannh287/tap/soundbar
open "$(brew --prefix)/opt/soundbar/SoundBar.app"
```

Homebrew builds from source on your machine, so the ad-hoc signature is enough and
Gatekeeper never sees a quarantined download.

### Update

```sh
brew update && brew upgrade soundbar
```

Homebrew replaces the bundle on disk but cannot touch the copy already running. Just open
the new one — it retires the old instance on launch, so the two never play at once. With
**Open at Login** on, a logout or reboot does the same thing.

Check what you have against what the tap offers:

```sh
brew info soundbar | head -3
```

## Thanks

Every app of this kind follows whichever window is frontmost. This one pins a window
instead, which is what makes the timer and the drift warning mean anything — but the hard
parts were all solved somewhere else first.

Read for their source:

- [dim-the-lights](https://github.com/iamashwincherian/dim-the-lights) — that the whole
  thing is possible with no TCC permission at all, and that the tracking timer belongs in
  the common run loop modes. Both were load-bearing here.
- [vignette](https://github.com/hrdmax/vignette) — the clearest write-up of the dead ends:
  why no public API can slip a window between another app's windows, and why the overlay
  sits one level below the Dock.
- [FocusDim](https://github.com/NikRpk/FocusDim) and
  [focus-window-dimmer](https://github.com/turhe123/focus-window-dimmer) — the window and
  collection-behaviour settings that survive Spaces and full screen.
- [NotchFocus](https://github.com/code-vagabond/notchfocus) — shaking something
  click-through as the warning.

Studied for their behaviour, not their code:

- [HazeOver](https://hazeover.com/) — the original distraction dimmer, and the multi-display
  rules it settled on.
- [Window Focus](https://apps.apple.com/app/id1142625137) and
  [Focusdim](https://alternativeto.net/software/focusdim) — per-app intensity and
  highlight-by-border as alternatives to one global dim.

Sounds are Apple's own Background Sounds assets.

## License

MIT

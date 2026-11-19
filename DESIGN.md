---
version: alpha
name: soundbar-design
source: "Claude design analysis — getdesign.md/claude/design-md (independent, unaffiliated)"
description: "One warm coral accent over a black scrim, with amber as the only other hue. SwiftUI menu bar app, so system materials and semantic colors carry the surfaces; only the accent is ours."

colors:
  primary: "#cc785c"
  warning: "#d4a017"
  on-primary: "#ffffff"

typography:
  scale: system
  tracking: default
---

## Scope

This is a macOS menu bar app, not a web page. The panel sits in an `NSVisualEffectView`
and the overlay paints black over the whole display. So the source system applies as a
**colour and restraint rule**, not as a token set to hardcode:

- **The accent is ours.** `Palette.accent` / `Palette.warning` in
  `Sources/FocusKit/UI/Style.swift` are the only hardcoded colours in the app.
- **Everything else is the system's.** `Color.primary` / `.secondary` / `.tertiary` and
  `NSColor.labelColor` track the user's appearance and accessibility settings; the
  source's ink ladder (`#141413` → `#8e8b82`, inverted on dark) is what they already resolve to.
- **Type is the system's.** `.headline` / `.subheadline` / `.footnote` / `.caption2`.
  The source leaves display type to the platform sans, and Dynamic Type beats a fixed px scale.

## Colour

| Role | Value | Where |
|---|---|---|
| accent | `#cc785c` | selected tile/chip fill, 7-day strip bars, overlay focus ring |
| warning | `#d4a017` | "Pinned window is gone" — the only other hue in the app |
| canvas | `NSColor.black` | the dim overlay — it must be true black, it is a scrim |
| surfaces | `Color.primary` at 0.07 / 0.14 / +0.06 hover | the one opacity ladder, `Surface.fill` |
| hairline | `Color.primary.opacity(0.25)`, 1px dashed | empty-preset chip only |

Rules, carried over from the source system:

- **Two hues, total.** Coral marks selection, amber marks the one failure state. The
  source's teal, green and red are not in use; adding one needs a reason in this file.
- **Coral accents, never fills.** It marks selection and the focus ring, not a background.
- **No hover hue.** The source documents default and pressed only; hover here is the
  opacity bump in `Surface.fill`, never a second colour.
- **One opacity ladder.** Tiles and chips share `Surface.fill`; adding a second scale is
  the drift this file exists to stop.
- **No gradients, no shadows.** Depth is the material plus the 1px hairline.

## Shape & motion

- Pills (`Capsule`) for chips and presets; `12pt` rounded rect for tiles. Nothing else.
- Chip padding `12×7` — the source's button padding at this app's smaller scale.
- Hover `1.02`, pressed `0.96`, `.easeOut(0.12)`. The overlay's own jolt is deliberately
  harsher — it is a warning, see the `Focus/` code.

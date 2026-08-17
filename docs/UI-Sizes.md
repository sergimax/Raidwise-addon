# Raidwise UI sizes

Reference for the main exporter window (`ExporterWindow.lua`). All units are WoW UI pixels. Values here must stay in sync with the `UI` table in that file.

## Window

| Element | Size | Notes |
|---------|------|-------|
| Main frame (`RaidwiseFrame`) | **420 × 460** | Movable, `DIALOG` strata, Esc-close via `UISpecialFrames` |
| Backdrop tile / edge | 32 / 32 | `UI-DialogBox` textures |
| Backdrop insets | 8 on each side | Content starts inside this border |
| Content padding (left / right) | 20 / 20 | From outer frame edge to controls |
| Content padding (top / bottom) | 16 / 16 | Top to title; bottom to last control |

## Header

| Element | Size / spacing | Notes |
|---------|----------------|-------|
| Title (`GameFontNormalLarge`) | height ~16 | Centered; text “Raidwise” |
| Version (`GameFontNormalSmall`) | height ~10 | 4 px under title |
| Close button (`UIPanelCloseButton`) | **32 × 32** | Blizzard template; top-right at (−4, −4) |

## Actions

| Element | Size | Notes |
|---------|------|-------|
| Export button | **380 × 28** | Full content width; primary action |
| Gap: version → export | 14 px | |
| Options row height | 28 px | Checkbox + label |
| Gap: export → options | 10 px | | 
| Include-names checkbox (`UICheckButtonTemplate`) | **24 × 24** | Hit target; Blizzard default is often 32 — we set explicitly |
| Gap: checkbox → label text | 4 px | Label uses `GameFontHighlight` |
| Status line (`GameFontNormalSmall`) | height ~10 | Full content width; 6 px under options |
| Gap: status → export panel | 10 px | |

## Export panel

| Element | Size | Notes |
|---------|------|-------|
| Panel label | height ~12 | “Character JSON — Ctrl+C to copy” |
| Gap: label → inset | 6 px | |
| Inset frame | fills remaining height | Backdrop; left/right/bottom anchored with 20 / 20 / 52 padding |
| Inset backdrop insets | 6 on each side | |
| Scroll frame | inset minus 8 px padding | Room for scrollbar on the right |
| Scrollbar gutter | 20 px | Right margin inside inset |
| EditBox width | inset inner width − scrollbar gutter | Multiline; `ChatFontNormal` |
| EditBox min height | 180 | Grows with content via `OnTextChanged` / cursor scroll |
| Gap: inset → Select All | 8 px | |
| Select All button | **140 × 24** | Centered under inset |

## Vertical stack (top → bottom)

```text
16  title
 4  version
14  Export Character (28)
10  options row (28)
 6  status
10  panel label
 6  inset (flex)
 8  Select All (24)
16  bottom padding
```

Approx fixed chrome above inset: **~138 px**. At frame height 460, inset ≈ **270 px** tall.

## Fonts (Blizzard objects)

| Role | Font object |
|------|-------------|
| Window title | `GameFontNormalLarge` |
| Version / status / hints | `GameFontNormalSmall` |
| Checkbox & section labels | `GameFontHighlight` |
| Export JSON | `ChatFontNormal` |

## Changing sizes

1. Edit the `UI` constants at the top of `ExporterWindow.lua`.
2. Update this document to match.
3. Reload the UI (`/reload`) and check `/raidwise show`.

# Raidwise UI sizes

Reference for the main window (`ExporterWindow.lua`). All units are WoW UI pixels. Values here must stay in sync with the `UI` table in that file.

View layouts (ASCII schemes) live in [`UI-Views.md`](UI-Views.md).

## Shell

| Element | Size | Notes |
|---------|------|-------|
| Content frame (`RaidwiseFrame`) | **520 × 480** | Movable, `DIALOG` strata, Esc-close via `UISpecialFrames` |
| Menu panel (`RaidwiseMenu`) | **170 × 480** | Anchored to content `TOPLEFT` with a 2 px gap |
| Status bar | height **20** | Spans menu left → content right, 2 px below both; name, version, GitHub link |
| Status bar padding | 8 px | Left / right |
| Status bar gap | 12 px | Between name and version |
| Title bar | height **20** | Top of content; only this (and the menu title) starts a drag |
| Menu title bar | height **20** | Top of menu; drag handle; label “Menu” |
| Close button | **16 × 16** | Right side of content title bar |
| Panel fill | RGB **0.15** | `ChatFrameBackground`, alpha 0.96 |
| Title / status fill | RGB **0.20** | Same texture |
| 1 px border | RGB **0,0,0** | Four edge textures (3.3.5-safe, Details-like) |

## Left menu

| Element | Size | Notes |
|---------|------|-------|
| Menu button | **158 × 22** | Width is `MENU_WIDTH - 12` |
| Gap between buttons | 2 px | |
| First button offset | 8 px below menu title | |
| Idle fill | RGB **0.18** | Menu + action buttons |
| Hover fill | RGB **0.28** | Label `{1, 1, 0.4}` |
| Selected fill | **0.32, 0.28, 0.12** | Gold label `{0.89, 0.73, 0.016}` |
| Disabled fill | RGB **0.12** | Label `{0.45, 0.45, 0.45}` |

Tabs (in order): **Export gear and CDs**.

## Content padding

| Element | Size | Notes |
|---------|------|-------|
| Page padding | 10 px | Inside content, below title bar |
| Page inner width | **500** | `520 - 10 - 10` |

## Export tab

See [`UI-Views.md`](UI-Views.md) for the ASCII scheme.

| Element | Size | Notes |
|---------|------|-------|
| Description | full inner width | `GameFontHighlight`; wraps via `SetWidth` |
| Gap: description → checkbox | 8 px | |
| Include-names checkbox | **24 × 24** | `UICheckButtonTemplate` |
| Options row height | 28 px | Checkbox + clickable label |
| Gap: checkbox → buttons | 10 px | |
| Export data / Select all | equal width × **28** | `(innerWidth - 8) / 2`; 8 px gap between |
| Gap: buttons → hint | 8 px | |
| Copy hint | full inner width | `GameFontNormalSmall` |
| Gap: hint → copy box | 6 px | |
| Copy box | fills remaining height | WowSims/AceGUI MultiLineEditBox: tooltip border, black fill |
| Copy box edge | 16 px | `UI-Tooltip-Border` |
| Copy box insets | 4 / 3 / 4 / 3 | left / right / top / bottom of backdrop |
| EditBox padding inside border | 5, 6, 4, 4 | left, top, right, bottom |
| Scrollbar | 20 px wide | Outside the bordered box, 2 px gap; 16 px inset top/bottom |
| EditBox line height | from `ChatFontNormal` | Face size + 2, or EditBox `cursorHeight` once known; not a hardcoded 12 px |
| EditBox min height | 180 | Grows from measured wrapped text height |

## Fonts

| Role | Font object | Color |
|------|-------------|-------|
| Window / menu titles | `GameFontNormal` | Gold `{0.89, 0.73, 0.016}` |
| Menu / action buttons | `GameFontNormalSmall` | Idle `{0.8, 0.8, 0.8}` |
| Version / status / hints | `GameFontNormalSmall` | Idle gray |
| GitHub link | `GameFontNormalSmall` | `{0.4, 0.7, 1}` (hover brighter) |
| Checkbox & section labels | `GameFontHighlight` | |
| Export JSON | `ChatFontNormal` | |

## Changing sizes

1. Edit the `UI` constants at the top of `ExporterWindow.lua`.
2. Update this document to match.
3. Reload the UI (`/reload`) and check `/raidwise show`.

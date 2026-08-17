# Raidwise UI sizes

Reference for the main window (`ExporterWindow.lua`). All units are WoW UI pixels. Values here must stay in sync with the `UI` table in that file.

The layout follows Details-style **plain panels**: a content window, a left menu panel, and a status bar under both.

```text
[ Menu 150 ] 2px [ Content 520 x 480 ]
                 [ title bar 20      ]
                 [ page body         ]
[ status bar 20 spanning both         ]
```

## Shell

| Element | Size | Notes |
|---------|------|-------|
| Content frame (`RaidwiseFrame`) | **520 × 480** | Movable, `DIALOG` strata, Esc-close via `UISpecialFrames` |
| Menu panel (`RaidwiseMenu`) | **150 × 480** | Anchored to content `TOPLEFT` with a 2 px gap |
| Status bar | height **20** | Spans menu left → content right, 2 px below both |
| Title bar | height **20** | Top of content; drag handle |
| Menu title bar | height **20** | Top of menu; label “Menu” |
| Close button | **16 × 16** | Right side of content title bar |
| Panel fill | RGB **0.15** | `ChatFrameBackground`, alpha 0.96 |
| Title / status fill | RGB **0.20** | Same texture |
| 1 px border | RGB **0,0,0** | Four edge textures (3.3.5-safe, Details-like) |

## Left menu

| Element | Size | Notes |
|---------|------|-------|
| Menu button | **138 × 22** | Width is `MENU_WIDTH - 12` |
| Gap between buttons | 2 px | |
| First button offset | 8 px below menu title | |
| Idle fill | RGB **0.18** | |
| Hover fill | RGB **0.28** | Label turns yellow |
| Selected fill | **0.32, 0.28, 0.12** | Gold label `{0.89, 0.73, 0.016}` |

Tabs (in order): **Export**.

## Content padding

| Element | Size | Notes |
|---------|------|-------|
| Page padding | 10 px | Inside content, below title bar |
| Page inner width | **500** | `520 - 10 - 10` |

## Export tab

| Element | Size | Notes |
|---------|------|-------|
| Export button | **500 × 28** | Full page width |
| Gap: export → options | 10 px | |
| Include-names checkbox | **24 × 24** | `UICheckButtonTemplate` |
| Options row height | 28 px | Checkbox + clickable label |
| Gap: checkbox → status | 6 px | |
| Gap: status → “Character JSON” | 8 px | |
| Gap: label → inset | 6 px | |
| JSON inset | fills remaining height | Darker panel `{0.08, 0.08, 0.08}` |
| Inset inner padding | 8 px | |
| Scrollbar gutter | 20 px | Right side of inset |
| EditBox min height | 180 | Grows with line count |
| Gap: inset → Select All | 8 px | |
| Select All button | **140 × 24** | Centered under inset |

## Fonts

| Role | Font object | Color |
|------|-------------|-------|
| Window / menu titles | `GameFontNormal` | Gold `{0.89, 0.73, 0.016}` |
| Menu buttons | `GameFontNormalSmall` | Idle `{0.8, 0.8, 0.8}` |
| Version / status / hints | `GameFontNormalSmall` | Idle gray |
| Checkbox & section labels | `GameFontHighlight` | |
| Export JSON | `ChatFontNormal` | |

## Changing sizes

1. Edit the `UI` constants at the top of `ExporterWindow.lua`.
2. Update this document to match.
3. Reload the UI (`/reload`) and check `/raidwise show`.

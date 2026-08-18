# Raidwise UI sizes

Reference for the main window (`ExporterWindow.lua`). All units are WoW UI pixels. Values here must stay in sync with the `UI` table in that file.

View layouts (ASCII schemes) live in [`UI-Views.md`](UI-Views.md).

## Shell

| Element | Size | Notes |
|---------|------|-------|
| Content frame (`RaidwiseFrame`) | **790 × 480** | Movable, `DIALOG` strata, Esc-close via `UISpecialFrames` |
| Menu panel (`RaidwiseMenu`) | **170 × 480** | Anchored to content `TOPLEFT` with a 2 px gap |
| Status bar | height **20** | Spans menu left → content right, 2 px below both; name and version |
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

Tabs (in order): **Character cooldowns**, **Party roster**, **Raid roster**, **History**, **Export gear and CDs**, **Export cooldowns**, **Info**.

## Content padding

| Element | Size | Notes |
|---------|------|-------|
| Page padding | 10 px | Inside content, below title bar |
| Page inner width | **770** | `790 - 10 - 10` |

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

## Info tab

See [`UI-Views.md`](UI-Views.md) for the ASCII scheme.

| Element | Size | Notes |
|---------|------|-------|
| Heading → body | 8 px | About / GitHub |
| Body → next heading | 14 px | |
| URL copy box | height **28** | Tooltip border; fills row minus Select all |
| Select all | **110 × 28** | Right of the URL box; 8 px gap |

## Character cooldowns tab

See [`UI-Views.md`](UI-Views.md) for the ASCII scheme.

| Element | Size | Notes |
|---------|------|-------|
| Toolbar row | height **28** | Hint left, Refresh right |
| Gap: toolbar → table | 8 px | Table starts below Refresh button |
| Refresh | **80 × 28** | Top-right of the page |
| Instance column | **170** | Name + type stacked |
| Character column | **90** | Spec icon **14 × 14**, then class-colored name |
| Header row | **38** | Title-bar fill |
| Data row | **34** | Alternate fills RGB **0.18** / **0.14** |
| Vertical scrollbar | **16** | Right of the table; hidden if unused |
| Horizontal scrollbar | **16** | Bottom of the table; hidden if unused |

## Party roster tab

Same toolbar as Character cooldowns, plus an averages line, then the scroll table (`CD_TOOLBAR_H`, `CD_HEADER_H`, `CD_ROW_H`, scrollbars).

| Element | Size | Notes |
|---------|------|-------|
| Averages line | height **16** | `Average iLvl: {n}     Average GS: {n}`; 8 px gap above and below |
| Columns | **90 + 28 + 28 + 52 + 44 + 52 + 100 + 184 = 578** | Name, class icon, spec icon, GS, iLvl, Karma, Tags, Guild |
| Class column | **14** px icon | `CLASS_ICON_TCOORDS`; tooltip shows localized class |
| Spec column | **14** px icon | Talent tree icon from `GetTalentTabInfo`; tooltip shows spec name |
| Karma column | **52**, center | Placeholder `4.3` until karma is implemented |
| Tags column | **100** | `#tag #tag`; placeholder until tag functions exist |
| Guild column | **184** | `GuildName (Rank)`; `-` when not in a guild |

Max **5** rows (player + `party1`–`party4`). Raid members are not listed here.

## Raid roster tab

Same toolbar + averages line as Party roster (`CD_TOOLBAR_H`, gap, scrollbars). Two stacked blocks inside the scroll child.

| Element | Size | Notes |
|---------|------|-------|
| Averages line | height **16** | Same as Party roster; mean of filled members with a value |
| Player cell | **148 × 72** | Four lines: class+name, spec+GS/iLvl, karma, tags |
| Cell gap | **2** | Between cells and columns |
| Group label | height **16** | Gold number above each party column |
| Block 1 | **5 × (148 + 2) − 2 = 748** | Parties 1–5 |
| Block 2 | **3 × (148 + 2) − 2 = 448** | Parties 6–8, left-aligned under block 1 |
| Gap between blocks | **12** | |
| Cell content | **14** px icons | Class on line 1, spec on line 2 |

## Character profile

Popup (`RaidwiseRaidCharacterFrame`), `FULLSCREEN_DIALOG` strata. Opened from Raid roster or History; Esc-close via `UISpecialFrames`.

| Element | Size | Notes |
|---------|------|-------|
| Window | **300 × 360** | Centered, offset +40 / +20 from parent center |
| Title bar | height **20** | Drag handle; `{name} - Character profile` |
| Close button | **16 × 16** | Right of title bar |
| Body padding | **10** | Same as main shell `PAD` |
| Icons | **14** | Class then spec, stacked |
| Line gap | **8** | Between body rows |

## History tab

Same toolbar + scroll table as Character cooldowns (`CD_TOOLBAR_H`, `CD_HEADER_H`, `CD_ROW_H`, scrollbars). No averages line.

| Element | Size | Notes |
|---------|------|-------|
| Columns | **90 + 28 + 28 + 52 + 44 + 160 + 130 + 150 = 682** | Name, class, spec, GS, iLvl, Met in, When, Guild |
| Met in | **160** | First meeting instance or zone |
| When | **130** | `YYYY-MM-DD HH:MM` |

## Export cooldowns tab

Same layout as Export gear and CDs, without the include-names checkbox. Description → **Export cooldowns** / **Select all** (28 px) → hint → copy box.

## Fonts

| Role | Font object | Color |
|------|-------------|-------|
| Window / menu titles | `GameFontNormal` | Gold `{0.89, 0.73, 0.016}` |
| Menu / action buttons | `GameFontNormalSmall` | Idle `{0.8, 0.8, 0.8}` |
| Version / status / hints | `GameFontNormalSmall` | Idle gray |
| Checkbox & section labels | `GameFontHighlight` | |
| Export JSON | `ChatFontNormal` | |

## Changing sizes

1. Edit the `UI` constants at the top of `ExporterWindow.lua`.
2. Update this document to match.
3. Reload the UI (`/reload`) and check `/raidwise show`.

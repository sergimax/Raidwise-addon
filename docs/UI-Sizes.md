# Raidwise UI sizes

Reference for the main window and pages. All units are WoW UI pixels. Shared theme and widgets live in `UIWidgets.lua`; shell sizes in `ExporterWindow.lua`; page-specific columns in each `Page*.lua`. Values here must stay in sync with those tables.

View layouts (ASCII schemes) live in [`UI-Views.md`](UI-Views.md). Architecture: [`Architecture.md`](Architecture.md).

## Shell

| Element | Size | Notes |
|---------|------|-------|
| Content frame (`RaidwiseFrame`) | **890 × 690** | Movable, `DIALOG` strata, Esc-close via `UISpecialFrames` |
| Menu panel (`RaidwiseMenu`) | **170 × 690** | Anchored to content `TOPLEFT` with a 2 px gap |
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

Tabs (in order): **Character cooldowns**, **Export gear and CDs**, **Party roster**, **Raid roster**, **Raid composition**, **History**, **Settings**, **Info**.

## Content padding

| Element | Size | Notes |
|---------|------|-------|
| Page padding | 10 px | Inside content, below title bar |
| Page inner width | **870** | `890 - 10 - 10` |

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
| Refresh | **96 × 28** | Top-right of the page |
| Instance column | **170** | Name + type stacked |
| Character column | **90** | Spec icon **14 × 14**, class-colored name, last check (`18 Aug 23:58`) |
| Header row | **52** | Title-bar fill; spec icon, name, then last check time |
| Data row | **34** | Alternate fills RGB **0.18** / **0.14** |
| Vertical scrollbar | **16** | Right of the table; hidden if unused |
| Horizontal scrollbar | **16** | Bottom of the table; hidden if unused |

## Party roster tab

Same toolbar as Character cooldowns, plus an averages line, then the scroll table (`CD_TOOLBAR_H`, `CD_HEADER_H`, `CD_ROW_H`, scrollbars).

| Element | Size | Notes |
|---------|------|-------|
| Averages line | height **16** | `Average iLvl: {n}     Average GS: {n}`; 8 px gap above and below |
| Columns | **90 + 28 + 28 + 166 + 52 + 44 + 60 + 100 + 176 = 744** | Name, class, spec, buffs, GS, iLvl, Opinion, Tags, Guild |
| Class column | **18** px icon | `CLASS_ICON_TCOORDS`; tooltip shows localized class |
| Spec column | **18** px icon | Talent tree icon from `GetTalentTabInfo`; tooltip shows spec name |
| Buffs column | **166** | Up to **8** raid-buff icons (**18** px, 2 px gap); hover shows the spell name |
| Opinion column | **60**, center | Symbol `+` / `=` / `-`; color-coded; tooltip shows full label |
| Tags column | **100** | Colored tag summary (up to 3 labels, then `+N`); `-` when none |
| Guild column | **176** | `GuildName (Rank)`; `-` when not in a guild |

Max **5** rows (player + `party1`–`party4`). Rows are clickable and open Character profile. Raid members are not listed here.

## Raid roster tab

Same toolbar as Party roster, then two stats lines, then the scroll host. Two stacked blocks inside the scroll child.

| Element | Size | Notes |
|---------|------|-------|
| Averages line | height **16** | `Average GS: {n}` only (no average iLvl; transmog skews it) |
| Role averages | height **16** | `Tanks: {n} ({gs} gs)` (and Healers, Melee, Range); `-` when no GS |
| Stats block | height **32** | Combined area for both stats lines (`RAID_STATS_H`) |
| Player cell | **168 × 106** | Five lines: class+name, role+spec+GS/iLvl, buff icons, personal opinion, tags |
| Cell gap | **2** | Between cells and columns |
| Group label | height **16** | Gold number above each party column |
| Block 1 | **5 × (168 + 2) − 2 = 848** | Parties 1–5 |
| Block 2 | **3 × (168 + 2) − 2 = 508** | Parties 6–8, left-aligned under block 1 |
| Gap between blocks | **12** | |
| Cell content | **20** px class/role/spec; **18** px buffs | Class on line 1; role then spec on line 2; up to **8** buff icons on line 3; line height **14** |

## Raid composition tab

Same toolbar as Character cooldowns (`CD_TOOLBAR_H`, 8 px gap). Vertical scrollbar only.

| Element | Size | Notes |
|---------|------|-------|
| Columns | **3** | Equal width; `COMP_COL_GAP` **12** px |
| Section heading | height **20** | Gold `GameFontNormal` |
| Effect row | height **20** | Icon **16** px, name, count width **22** |
| Gap between sections | **10** px | After packing into the shortest column |

## Character profile

Popup (`RaidwiseRaidCharacterFrame`), `FULLSCREEN_DIALOG` strata. Opened from Party roster, Raid roster, or History; Esc-close via `UISpecialFrames`. No window scroll — tab panels fill the body below the summary. Layout rebuild gated by `PROFILE_LAYOUT_VERSION` (title-bar badge `vN`).

| Element | Size | Notes |
|---------|------|-------|
| Window | **460 × 560** | Centered, offset +40 / +20 from parent center |
| Title bar | height **20** | Drag handle; `{name} - Character profile`; layout badge `vN` before close |
| Close button | **16 × 16** | Right of title bar |
| Body padding | **10** | Same as main shell `PAD` |
| Content width | **440** | `460 - 10×2` |
| Header icons | **24** | Race + class in left cell; spec in right cell (`PROFILE_ICON`); column gap **12** |
| Summary | height **122** | Opinion, tags, facts, guild, GUID, realm (+ community column) |
| Profile tabs | height **26** | **History**, **Note**, **Facts**, **Events**, **Memo**; gap **4** |
| Tab host | fills body below tabs | Panels swap in place |
| Opinion radios | **3** equal columns × **22** | Exclusive Positive / Neutral / Negative |
| Tag checkboxes | scrolling columns by category | Max **3** tags per category; category heading gold |
| Fact checkboxes | two columns under Facts tab | Max **4** facts |
| Event type picker | scroll **~96** tall | Full width under pick label; **Add event** top-right with heading |
| Event list | fills remaining Events tab | Fixed **20** px rows (label + Remove) |
| Memo hint | under heading | `GameFontNormalSmall`; personal-use only (not History) |
| Memo box | **440 × 96** | Multiline EditBox with inner scroll |
| Memo Save / Reset | half width × **28** | `(contentWidth - 8) / 2`; gap **8** |
| History Met / party count | first row of History tab | **Met** left-aligned; **Was in the same party** right-aligned (`meetCount`) |
| Community mock block | right summary column | Gold heading + wrapped body text |

Rating editor requires a valid GUID; controls are disabled when GUID is missing. Bottom window **Save and Update** appears on **Note** / **Facts** / **Events** and commits those drafts (not memo). Hidden on **History** and **Memo**. Header personal note/tags/facts stay on saved values until that commit. Closing without Save discards drafts.

## History tab

Same toolbar + scroll table as Character cooldowns (`CD_TOOLBAR_H`, `CD_HEADER_H`, `CD_ROW_H`, scrollbars). No averages line.

| Element | Size | Notes |
|---------|------|-------|
| Columns | **90 + 28 + 28 + 70 + 120 + 52 + 44 + 140 + 130 + 120 = 822** | Name, class, spec, Opinion, Tags, GS, iLvl, Met in, When, Guild |
| Class / spec icons | **18** px | Centered in 28 px columns |
| Opinion column | **70**, center | Symbol `+` / `=` / `-`; color-coded |
| Tags column | **120** | Colored tag summary (up to 3 labels, then `+N`); `-` when none |
| Met in | **140** | First meeting instance or zone |
| When | **130** | `YYYY-MM-DD HH:MM` |
| Guild | **120** | Last stored `GuildName (Rank)` |

Rows are clickable and open Character profile. Notes are stored on the history record but edited only in Character profile.

## Settings tab

Language heading, hint, then two **120 × 28** locale buttons (**English**, **Русский**) with an 8 px gap. Selected button uses the same gold fill as the left menu.

## Fonts

| Role | Font object | Color |
|------|-------------|-------|
| Window / menu titles | `GameFontNormal` | Gold `{0.89, 0.73, 0.016}` |
| Menu / action buttons | `GameFontNormalSmall` | Idle `{0.8, 0.8, 0.8}` |
| Version / status / hints | `GameFontNormalSmall` | Idle gray |
| Checkbox & section labels | `GameFontHighlight` | |
| Export JSON / profile notes | `ChatFontNormal` | |

## Changing sizes

1. Edit the `UI` / theme constants in `UIWidgets.lua`, `ExporterWindow.lua`, or the relevant `Page*.lua`.
2. Bump that view’s `LAYOUT_VERSION` when structure or named frames change.
3. Update this document and [`UI-Views.md`](UI-Views.md) to match (include the new `vN`).
4. Reload the UI (`/reload`) and check `/raidwise` (layout rebuild should also fire when versions mismatch).

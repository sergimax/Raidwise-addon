# Raidwise UI sizes

Reference for the main window and pages. All units are WoW UI pixels. Shared theme and widgets live in `UIWidgets.lua`; shell sizes in `ExporterWindow.lua`; page-specific columns in each `Page*.lua`. Values here must stay in sync with those tables.

View layouts (ASCII schemes) live in [`UI-Views.md`](UI-Views.md). Architecture: [`Architecture.md`](Architecture.md).

## Shell

| Element | Size | Notes |
|---------|------|-------|
| Content frame (`RaidwiseFrame`) | **890 × 940** | Movable, `DIALOG` strata, Esc-close via `UISpecialFrames` |
| Menu panel (`RaidwiseMenu`) | **170 × 940** | Flush against content left edge (no gap) |
| Menu title bar | height **20** | Top of menu; drag handle; centered **Raidwise** + dim addon semver (same fonts/colors as content title + page `vN`) |
| Menu title gap | 8 px | Between name and version (matches content title bar) |
| Title bar | height **20** | Top of content; drag handle; **active menu name** + page `vN` + close **X** |
| Close button | **16 × 16** | Right side of content title bar |
| Page layout badge | in title bar | `v` + page `LAYOUT_VERSION`, immediately right of the menu name |
| Panel fill | **#12121c** ≈ RGB **0.07, 0.07, 0.11** | Classic theme; alpha 0.98; flat fill (no border edges) |
| Title / status fill | **#1c1c2a** ≈ RGB **0.11, 0.11, 0.165** | Same texture |
| Gear Check gradation | red → green | `GEAR_BAD` / `GEAR_REPLACE` / `GEAR_OK` / `GEAR_GOOD` — verdicts (BAD…GOOD) and spec ranks (forbidden…preferred) |
| Idle text | **#ffeebb** ≈ RGB **1.00, 0.93, 0.73** | Body / menu idle |

## Left menu

| Element | Size | Notes |
|---------|------|-------|
| Menu button | **158 × 22** | Width is `MENU_WIDTH - 12`; **16×16** icon left, label to the right |
| Menu icon | **16 × 16** | `Interface\Icons\…` per tab; TexCoord crop `0.07–0.93` |
| Gap between buttons | 2 px | |
| First button offset | 8 px below menu title | |
| Idle fill | **0.125, 0.110, 0.165** | Menu + action buttons |
| Hover fill | **0.180, 0.150, 0.200** | Label `{1.00, 0.91, 0.55}` |
| Selected fill | **0.230, 0.188, 0.125** | Gold label `{1.00, 0.82, 0.00}` |
| Disabled fill | **0.055, 0.055, 0.078** | Label `{0.69, 0.63, 0.44}` |

Tabs (in order): **Character cooldowns** (watch), **Export gear and CDs** (note), **Party roster** (Prayer of Fortitude), **Raid roster** (Glory of the Raider), **Raid composition** (Greater Blessing of Kings), **Gear check (target)** (spyglass), **History** (book), **Settings** (gear), **Info** (question mark).

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
| Copy box | fills remaining height | Black fill; spacing from `COPY_PAD_*` and scrollbar gap (no tooltip border) |
| Copy box insets | — | Padding via scroll anchors: **5 / 4 / 4 / 4** (`COPY_PAD_L/T/R/B`) |
| EditBox padding inside box | 5, 6, 4, 4 | left, top, right, bottom |
| Scrollbar | 20 px wide | Outside the copy host, 2 px gap; 16 px inset top/bottom |
| EditBox line height | from `ChatFontNormal` | Face size + 2, or EditBox `cursorHeight` once known; not a hardcoded 12 px |
| EditBox min height | 180 | Grows from measured wrapped text height |

## Info tab

See [`UI-Views.md`](UI-Views.md) for the ASCII scheme.

| Element | Size | Notes |
|---------|------|-------|
| Feature icon | **18 × 18** | Same `Interface\Icons\…` as left menu; TexCoord crop `0.07–0.93` |
| Feature title + `vN` | gold title, disabled version | Version is that page’s `LAYOUT_VERSION` |
| Gap between feature blocks | **12** px | |
| Heading → body | 8 px | About / GitHub |
| Body → next heading | 14 px | |
| URL copy box | height **28** | Black fill; internal 8 px horizontal / 4 px vertical padding |
| Select all | **130 × 28** | Right of the URL box; 8 px gap |
| Vertical scroll | **16** | Right of content when sections exceed the page |

## Character cooldowns tab

See [`UI-Views.md`](UI-Views.md) for the ASCII scheme.

| Element | Size | Notes |
|---------|------|-------|
| Toolbar row | height **28** | Hint left, Refresh right |
| Gap: toolbar → table | 8 px | Table starts below Refresh button |
| Refresh | **96 × 28** | Top-right of the page |
| Instance column | **170** | Name + type stacked |
| Character column | **90** | Spec icon **14 × 14**, class-colored name, last check (`18 Aug 23:58`), **Remove** **82 × 16** on non-current characters |
| Header row | **68** | Page-local in `PageCooldowns.lua` (taller: spec icon, name, last check, Remove) |
| Data row | **34** | Alternate fills **0.094 / 0.078** (Classic `CD_ROW_A` / `CD_ROW_B`) |
| Currency rows | **1** fixed | **Currency** / **Валюта** title + label column; ~**175** px tall; aligned icon+count chips |
| Vertical scrollbar | **16** | Right of the table; hidden if unused |
| Horizontal scrollbar | **16** | Bottom of the table; hidden if unused |

## Party roster tab

Same toolbar as Character cooldowns, plus an averages line, then the scroll table (`CD_TOOLBAR_H`, `UI.CD_HEADER_H` **52**, `CD_ROW_H`, scrollbars).

| Element | Size | Notes |
|---------|------|-------|
| Header row | **52** | `UI.CD_HEADER_H` (single-line column labels) |
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

Description block with **Scan** / **Export** / **Refresh** in a right column, gear-check status, optional progress bar, combined stats line, gear summary, then the scroll host. Two stacked blocks inside the scroll child. `LAYOUT_VERSION = 10`.

| Element | Size | Notes |
|---------|------|-------|
| Button column | **104** px wide (Refresh **96** px, right-aligned) | **Scan**, **Export**, **Refresh** stacked top → bottom; **4** px gap; **8** px gap from description |
| Short description | left column | Top-aligned; wraps beside buttons |
| Gear check status | under description | `GameFontNormalSmall`; rating legend or scan/export/rescan progress; wraps |
| Progress bar | height **14** | Left column only; shown during raid scan/export/rescan |
| Stats line | height **16** | One line: `Average GS: {n}` + Tanks / Healers / Melee / Range role summaries |
| Gear check summary | height **16** | `BAD · REPLACE · OK · GOOD · Failed`; dim until first scan |
| Player cell | **168 × 152** | Eight text lines + one button row: class+name, role+spec+GS/iLvl, buff icons, opinion, tags, **armor/weap grade**, **ench/sock grade**, **Profile** + **Gear** + **Rescan** |
| Cell buttons | **16** tall | One row of three equal buttons (~**52** px each). Gear check disabled until scanned; Rescan disabled while any scan/export runs |
| Cell gap | **2** | Between cells and columns |
| Group label | height **16** | Group number (gold) + **3** party-only buff icons (**14** px, 1 px gap): Heroic Presence, Vampiric Embrace, Mana Tide Totem; full color = present in group, red tint = missing; hover shows spell name and provider names |
| Block 1 | **5 × (168 + 2) − 2 = 848** | Parties 1–5 |
| Block 2 | **3 × (168 + 2) − 2 = 508** | Parties 6–8, left-aligned under block 1 |
| Gap between blocks | **12** | |
| Cell content | **20** px class/role/spec; **18** px buffs | Class on line 1; role then spec on line 2; up to **8** buff icons on line 3; line height **14** |

Inspect queue runs sequentially; target scan blocked while raid scan is active. Per-player **Rescan** upserts that member’s result without clearing the rest of the raid results. Export builds dumps one player per frame (progress on this page) before opening Gear check (target).

## Raid composition tab

Same toolbar as Character cooldowns (`CD_TOOLBAR_H`, 8 px gap). Vertical scrollbar only.

| Element | Size | Notes |
|---------|------|-------|
| Toolbar | hint left; **Report missing** **110 × 28** then **Refresh** **96 × 28** | 4 px gap between buttons |
| Top summary | full width | Roles (left) + Classes (right) on one band |
| Role chip | icon **16** + count, width **34** | Gap **6** px (same as class chips) |
| Class chip | icon **16** + count, width **34** | Gap **6** px; all 10 classes |
| Gap under summary | **12** px | Before 3-column checklist |
| Columns | **3** | Equal width; `COMP_COL_GAP` **12** px |
| Section heading | height **20** | Gold `GameFontNormal` |
| Effect row | height **20** | Icon **16** px, name, count width **36** (right-aligned, no wrap) |
| Gap between sections | **10** px | After packing into the shortest column |

## Gear check (target) tab

Full-width description + limitation, then **two columns** (`LEFT_W ≈ innerW − 220 − 10`, right sidebar **220** px). Left: summary (**124** px), five report buttons, five filters, breakdown scroll. Right top band (**~144** px): multi-line status, **Scan**, **Show as a text**, **Select all**; report row starts below the taller of summary vs top band. Lower right: **Save report**, **Delete selected report**, scrollable saved list. Text view replaces main body; top band stays. `LAYOUT_VERSION = 10`.

| Element | Size | Notes |
|---------|------|-------|
| Left column | **~670** px | `innerW − RIGHT_COL_W − COL_GAP` |
| Right column | **220** px | Top band + saved sidebar |
| Summary (left) | height **124** | Top block; report row below `max(124, right top)` |
| Class / spec icons | **18** px | On who line under Overall; tooltips show class / spec names |
| Right top band | height **~144** | Status + 3 stacked buttons |
| Report / filter rows | left width only | Five equal buttons each |
| Breakdown | left, fills height | Slot groups with verdict color |
| Saved list | right sidebar below delete | Scroll + vertical bar; all entries (not capped) |

Raid-wide gear check is integrated into **Raid roster** (see that section). There is no separate gear-check raid tab.

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
| Profile tabs | height **26** | **History**, **Edit note**, **Facts**, **Events**, **Memo**; gap **4**; **History** opens by default |
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

Rating editor requires a valid GUID; controls are disabled when GUID is missing. Bottom window **Save and Update** appears on **Edit note** / **Facts** / **Events** and commits those drafts (not memo). Hidden on **History** and **Memo**. Header personal note/tags/facts stay on saved values until that commit. Closing without Save discards drafts.

## History tab

Same toolbar + scroll table as Party roster (`CD_TOOLBAR_H`, `UI.CD_HEADER_H` **52**, `CD_ROW_H`, scrollbars). No averages line.

| Element | Size | Notes |
|---------|------|-------|
| Header row | **52** | `UI.CD_HEADER_H` (single-line column labels) |
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

Below: **Startup page** heading, hint, then an **4-column** radio group (`UIRadioButtonTemplate`, **16** px, row **22**, 8 px gaps); selected page is stored in `RaidwiseDB.startupTab`.

Below: **Unit tooltips** heading, hint, four **24 × 24** checkboxes with labels, then **Preview** with compact + stacked sample blocks (`LAYOUT_VERSION = 6`).

## Fonts

| Role | Font object | Color |
|------|-------------|-------|
| Window / menu titles | `GameFontNormal` | Gold `{1.00, 0.82, 0.00}` |
| Menu / action buttons | `GameFontNormalSmall` | Idle `{1.00, 0.93, 0.73}`; hover `{1.00, 0.91, 0.55}`; selected gold |
| Version / status / hints | `GameFontNormalSmall` | Idle text / `TEXT_DISABLED` |
| Checkbox & section labels | `GameFontHighlight` | |
| Export JSON / profile notes | `ChatFontNormal` | |

## Shared widgets (`UIWidgets.lua`)

Key helpers used across pages (not on `Raidwise` directly):

| Helper | Role |
|--------|------|
| `ApplyPlainPanel` / `ApplyPanelBorderColor` | Flat backdrop fill (no border edges) |
| `CreatePlainButton` / `SetPlainButtonState` / `SetMenuButtonState` | Menu and action buttons |
| `CreateCopyBox` / `CreateLineCopyBox` | Export and URL copy areas |
| `SetSpecOrClassIcon` / `SetSpellIconTexture` / `CreateBuffIconHost` | Class, spec, buff icons |
| `TableIconInset` / `TableIconTopOffset` | Center icons in table rows |
| `AttachLayoutVersionLabel` | Profile title-bar `vN` badge |
| `RatingOpinionSymbol` / `RatingOpinionColor` / `ShowMemberRatingTooltip` | Opinion display in roster tables |

## Changing sizes

1. Edit the `UI` / theme constants in `UIWidgets.lua`, `ExporterWindow.lua`, or the relevant `Page*.lua`.
2. Bump that view’s `LAYOUT_VERSION` when structure or named frames change.
3. Update this document and [`UI-Views.md`](UI-Views.md) to match (include the new `vN`).
4. Reload the UI (`/reload`) and check `/raidwise` (layout rebuild should also fire when versions mismatch).

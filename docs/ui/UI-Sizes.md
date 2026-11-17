# UI geometry owners

Use the [UI task map](UI-Views.md) for current layout versions and checks.
Geometry is implemented in Lua; this guide retains a small outer-size reference
and routes detailed changes to their owners. Apply [layout rules](../../AGENTS.md#layout-versions)
when pixels or structure change; update the affected reference values here.
Sizes use unscaled WoW UI coordinates, not a physical-screen guarantee.

## Current outer geometry

| Element | Default size | Authoritative source |
|---|---|---|
| Main frame, including title/navigation | 970 × 693 | `UITheme.CONTENT_WIDTH` / `CONTENT_HEIGHT`; `ExporterWindow.CreateMainFrame` |
| Navigation column | 90 wide | `UITheme.MENU_BAR_W`; shell menu anchors |
| Page viewport | 868 × 653 | `CreateMainFrame` content anchors: left `MENU_BAR_W + 2`, top `TITLE_H + PAD`, right/bottom `PAD` |
| Profile popup | 820 × 540 | `ProfileWindow.lua`: `WIDTH`, `HEIGHT` |
| Diagnostics popup | 620 × 420 | `Diagnostics.ShowDiagnostics`: `SetSize` |

## Find detailed dimensions

Paths below are relative to `Raidwise/`. Read bounded sections around the named
constant/builder; labels and behavior are owned by the subsystem task maps.

| Element | Owner / search entry point |
|---|---|
| Shell title, menu spacing, content padding | `UITheme.lua`: `TITLE_H`, `MENU_*`, `PAD`; `ExporterWindow.lua`: `CreateTitleBar`, `CreateMainFrame` |
| Contextual report controls | `ExporterWindow.lua`: `CreateHeaderReportChannels`, `CreateHeaderReportForm`, `UpdateShellHeader` |
| Raid cards, bands and group scroll | `PageRaid.lua`: `RAID_CELL_W`, `RAID_CELL_H`, `CreateRaidPlayerCell`, `CreateRaidRosterHeader`, `CreateRaidRosterPage`; `UITheme.RAID_*` |
| Target gear columns, summary and saved list | `PageGearCheckTarget.lua`: `RIGHT_COL_W`, `COL_GAP`, `SUMMARY_H`, `TOP_BLOCK_H`, `CreateGearCheckTargetPage` |
| Role/class/effect composition controls | `PageComposition.lua`: `CreateCompositionPage`, `RefreshCompositionView` |
| Guild headers, columns, rows and editor | `Raidwise_Guild/PageGuild.lua`: `Columns`, `LayoutTable`, `Create` |
| Profile title, expanded editor, note and paged lists | `ProfileWindow.lua`: `WIDTH`, `HEIGHT`, `Create`, `List`, `Refresh`; no retired `CharacterProfile` geometry |
| History/database table and toolbar | `PageHistory.lua`: `CreateHistoryRow`, `CreateHistoryPage`; page registration selects history/database |
| Cooldown table, scroll bars and headers | `PageCooldowns.lua`; `UIWidgets.lua`: `CreateCooldownScrollBar`, `LayoutTableScrollBars`, `CooldownTableTopOffset` |
| Export/info/settings content | `PageExport.lua`, `PageInfo.lua`, `PageSettings.lua`; shared copy/input builders below |
| Copy boxes, text measurement and input insets | `UIWidgets.lua`: `CreateCopyBox`, `FitCopyBoxToText`, `ChatFontLineHeight`, `CreateLineCopyBox`, `CreateTextInput`; `UITheme.COPY_*` |
| Fonts and theme bindings | `UITheme.lua`: `CreateFontString`, `ApplyTheme`, `SetFontColor`; `UIWidgets.lua`: `ApplyFontSize` |
| Independent diagnostics scroll/edit area | `Diagnostics.lua`: `ShowDiagnostics`; its named scroll frame and edit-box dimensions |

Detailed anchors/columns/padding are not duplicated as Markdown schematics.
Historical Import/Share/Karma layouts are outside the active UI; see the
[character map](../characters/Reputation.md#historical-code). HTML concepts remain
available through the [design index](index.html). Native visual checks are in the
[UI map](UI-Views.md#native-client-constraints-and-verification).

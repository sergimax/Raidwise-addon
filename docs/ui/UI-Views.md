# UI task map and layout versions

Start here for shell, page, theme and shared-control work. Paths below are
relative to `Raidwise/` unless a companion addon is named. Search the entry point
before its helpers; [Architecture](../Architecture.md) routes behavior outside UI.

| Change | Owner / search entry point | Checks |
|---|---|---|
| Navigation, startup tab or title/report controls | `ExporterWindow.lua`: `CreateMainFrame`, `SelectTab`, private `UpdateShellHeader`; `PAGES`, `MENU_GROUPS` | [architecture](../../tests/architecture.test.mts), header cases in [gear-check](../../tests/gear-check.test.mts) |
| Page entry, localization or registration | Owning `Addon.Pages.*` registration: `Create`, `Refresh(page, entering)`, `ApplyLocale`; `ExporterWindow.lua`: `RefreshLocalizedUI` | [architecture](../../tests/architecture.test.mts): entry versus locale refresh |
| Stale shell/page generation | `ExporterWindow.lua`: private `PageLayoutStale`, `ShellNeedsRebuild`, `TearDownMainFrame` | Inspect these comparisons when changing rebuild behavior; page lifecycle/stamp fixtures are in [architecture](../../tests/architecture.test.mts) |
| Shared dimensions, colors or fonts | `UITheme.lua`: constants, `ApplyTheme`, `SetTheme`; [geometry owners](UI-Sizes.md) | [theme](../../tests/theme.test.mts): stable palette references and bindings |
| Inputs, buttons, copy boxes or dragging | `UIWidgets.lua`: `CreateTextInput`, `CreateCopyBox`, `FitCopyBoxToText`, `CreatePlainButton`, `AttachDragHandle` | [theme](../../tests/theme.test.mts); native templates/clipboard need client checks below |
| Roster cards, grades, consumables or opinion renderers | `RosterWidgets.lua`; owning page creates/anchors the controls | [gear map](../gear-check/Gear-Check-Progress.md), [character map](../characters/Reputation.md), [composition map](../raid/Raid-Composition.md) |
| Profile popup and its separate lists | `ProfileWindow.lua`: private `Create`, `List`, `Refresh`; public `ShowRaidCharacterWindow`; `ProfileEditor.lua`, `ProfileCharacters.lua` | [profile-window](../../tests/profile-window.test.mts): interactions, anchors and named template-scroll requirement |
| Diagnostics popup | `Diagnostics.lua`: `ShowDiagnostics` | [architecture](../../tests/architecture.test.mts): diagnostics/native-template fixture |
| Guild table/editor | `Raidwise_Guild/PageGuild.lua`: private `LayoutTable`, `Create`, `Refresh` | [guild map](../raid/Guild-Management.md) |

## Active views and layout versions

The code owns these values; this table is the required layout inventory under
[AGENTS.md](../../AGENTS.md#layout-versions). For geometry/structural changes apply
that rule and update this table plus affected [sizes](UI-Sizes.md).
Documentation cleanup alone does not change the registered generation.

| View | Registration / entry | Current constant | Owner |
|---|---|---|---|
| Main shell | `CreateMainFrame` | `SHELL_LAYOUT_VERSION = 34` | [ExporterWindow.lua](../../Raidwise/ExporterWindow.lua) |
| Guild roster / journal | `Addon.Pages.Guild` | `LAYOUT_VERSION = 7` | [PageGuild.lua](../../Raidwise_Guild/PageGuild.lua) |
| Diagnostics | `ShowDiagnostics` | `LAYOUT_VERSION = 2` | [Diagnostics.lua](../../Raidwise/Diagnostics.lua) |
| Profile | `ShowRaidCharacterWindow` | `PROFILE_LAYOUT_VERSION = 40` | [ProfileWindow.lua](../../Raidwise/ProfileWindow.lua) |
| Cooldowns | `Addon.Pages.Cooldowns` | `LAYOUT_VERSION = 9` | [PageCooldowns.lua](../../Raidwise/PageCooldowns.lua) |
| Gear / cooldown export | `Addon.Pages.Export` | `LAYOUT_VERSION = 5` | [PageExport.lua](../../Raidwise/PageExport.lua) |
| Raid | `Addon.Pages.Raid` | `LAYOUT_VERSION = 61` | [PageRaid.lua](../../Raidwise/PageRaid.lua) |
| Composition | `Addon.Pages.Composition` | `LAYOUT_VERSION = 10` | [PageComposition.lua](../../Raidwise/PageComposition.lua) |
| Target Gear Check | `Addon.Pages.GearCheckTarget` | `LAYOUT_VERSION = 20` | [PageGearCheckTarget.lua](../../Raidwise/PageGearCheckTarget.lua) |
| History | `Addon.Pages.History` | `LAYOUT_VERSION = 8` | [PageHistory.lua](../../Raidwise/PageHistory.lua) |
| Character database | `Addon.Pages.Database` | `DATABASE_LAYOUT_VERSION = 13` | [PageHistory.lua](../../Raidwise/PageHistory.lua) |
| Settings | `Addon.Pages.Settings` | `LAYOUT_VERSION = 19` | [PageSettings.lua](../../Raidwise/PageSettings.lua) |
| Info | `Addon.Pages.Info` | `LAYOUT_VERSION = 5` | [PageInfo.lua](../../Raidwise/PageInfo.lua) |

Shell version is rebuild-only. Badge placement and frame-stamping requirements
are defined in AGENTS. Page content and header capabilities belong to the page
registration; shared shell controls read `capabilities.reportChat` / `reportForm`.
Profile exchange/Karma have no active views; their future constraints are in [Synchronization.md](../characters/Synchronization.md).

## Native-client constraints and verification

- Read `CreateTextInput`'s source comment before changing Wrath input templates.
  `UIPanelScrollFrameTemplate` controls need nonempty frame names; the active
  profile mock rejects anonymous ones; diagnostics has a separate named-template
  and window-reuse check.
- `UITheme.ApplyTheme` preserves color-table identity because views retain those
  references. Follow its binding/font helpers instead of modifying global game
  font objects; game tooltips are outside addon text adjustments.
- Existing mocks cover behavior and selected anchor/template assumptions, not
  the native template engine, font rendering or complete shell-rebuild parity.

For affected changes check fresh construction and reopening/rebuilds, all active
pages, both locales/themes and UI scales. Exercise header control visibility,
long text, scrolling, tooltips, dragging, selection and actual clipboard copying.
Record date/revision/scenarios for client evidence; these reference docs are not
an acceptance report. Subsystem protocols: [profile](../characters/Character-System-Verification.md),
[gear](../gear-check/Gear-Check-Verification.md), [guild/composition](../raid/Guild-Management-Verification.md).

## Design references

[HTML index](index.html) preserves theme, roster-cell and scan-color explorations
with sample data. They are design references, not screenshots or executable
specifications of the current addon. Determine adopted behavior/geometry from
Lua and use the client checks above for actual visual parity.

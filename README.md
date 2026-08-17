# Raidwise

WoW addon for **Wrath of the Lich King 3.3.5a** (`Interface: 30300`).

![](https://img.shields.io/badge/current_version-1.0.0-purple)
![](https://img.shields.io/badge/last_updated-2026--08--16-blue)


## Install

1. Copy the `Raidwise` folder into your client’s AddOns directory:

   ```text
   <WoW>/Interface/AddOns/Raidwise/
   ```

2. Restart the client (or `/reload`).
3. Enable **Raidwise** on the character select AddOns screen if needed.
4. If you previously used **mrc-exporter**, remove that folder from AddOns so only Raidwise loads.


## Usage

In-game slash commands:

| Command | Description |
|---------|-------------|
| `/raidwise` or `/rw` (also `help`) | Show help |
| `/raidwise version` | Show addon version |
| `/raidwise status` | Show load status |
| `/raidwise show` | Open the main window |
| `/raidwise hide` | Close the main window |

In the window:

- Version is shown under the title
- **Export Character** fills the JSON panel (name, class, spec, gearScore, gear, bags, lockouts), selects the text, and prompts Ctrl+C
- **Include item names** toggles whether `names` arrays are included in the export
- **Select All** re-highlights the JSON if the selection was cleared
- `gearScore` comes from the **GearScore** addon when it is installed (optional dependency)

UI element sizes are documented in [`docs/UI-Sizes.md`](docs/UI-Sizes.md).

Consumers can type the export JSON with `types/CharacterExport.ts`.

## Screenshots:
Main addon view (`/raidwise show`):

![Main addon view](./screenshots/main-view.png)

In-chat menu (`/raidwise help`):

![In-chat menu](./screenshots/in-chat-menu.png)

# Development

## Layout

```text
Raidwise/
  Raidwise.toc        # addon metadata (Interface 30300)
  Raidwise.lua        # entry point, events, slash commands
  CharacterExport.lua # character JSON export (gear, bags, lockouts)
  ExporterWindow.lua  # main in-game window
docs/
  UI-Sizes.md         # window / control pixel sizes
types/
  CharacterExport.ts  # TypeScript types for the export JSON
```

## Notes

- Target build: **3.3.5a** (private-server style clients use `## Interface: 30300`).
- Saved variables are stored in `RaidwiseDB` (`WTF/Account/.../SavedVariables/`). Settings from the old `MrcExporterDB` are migrated on first load.
- `## X-LastUpdated` in the `.toc` is set manually; keep the README badge in sync.
- Optional dependency: **GearScore** (`## OptionalDeps`) for the `gearScore` export field.

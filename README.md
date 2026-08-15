# My Raid CDs Exporter

WoW addon for **Wrath of the Lich King 3.3.5a** (`Interface: 30300`).

![](https://img.shields.io/badge/current_version-0.3.0-purple)
![](https://img.shields.io/badge/last_updated-2026--08--15-blue)


## Install

1. Copy the `mrc-exporter` folder into your client’s AddOns directory:

   ```text
   <WoW>/Interface/AddOns/mrc-exporter/
   ```

2. Restart the client (or `/reload`).
3. Enable **mrc-exporter** on the character select AddOns screen if needed.


## Usage

In-game slash commands:

| Command | Description |
|---------|-------------|
| `/mrc` or `/mrcexporter` (also `help`) | Show help |
| `/mrc version` | Show addon version |
| `/mrc status` | Show load status |
| `/mrc show` | Open the main window |
| `/mrc hide` | Close the main window |

In the window:

- Version is shown under the title
- **Export Gear** fills the text area with character JSON (name, class, spec, gear, bags); focus the box and use Ctrl+C to copy
- **Include item names** toggles whether `names` arrays are included in the export

## Screenshots:
Main addon view:

![Main addon view](./screenshots/main-view.png)

In-chat menu:

![In-chat menu](./screenshots/in-chat-menu.png)

# Development

## Layout

```text
mrc-exporter/
  mrc-exporter.toc    # addon metadata (Interface 30300)
  mrc-exporter.lua    # entry point, events, slash commands
  CharacterExport.lua # equipped gear ID/name export
  ExporterWindow.lua  # main in-game window
```


## Notes

- Target build: **3.3.5a** (private-server style clients use `## Interface: 30300`).
- Saved variables are stored in `MrcExporterDB` (`WTF/Account/.../SavedVariables/`).
- `## X-LastUpdated` in the `.toc` is set manually; keep the README badge in sync.

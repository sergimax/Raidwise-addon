# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [0.5.0] - 2026-08-15

### Added
- Optional `gearScore` field in the character JSON export, read from the **GearScore** addon (same value as the character window)
- `## OptionalDeps: GearScore` so GearScore loads before mrc-exporter when both are installed
- `gearScore?: number` on the TypeScript `CharacterExport` type

## [0.4.0] - 2026-08-15

### Added
- Raid and dungeon instance lockouts in the character JSON export (`lockouts`: name, id, reset timers, difficulty, locked/extended flags)
- Fresh lockout data via `RequestRaidInfo` on login and when exporting
- TypeScript types for the export payload (`types/CharacterExport.ts`), including `InstanceDifficulty` and optional item `names`

## [0.3.0] - 2026-08-15

### Added
- Character JSON export with name, class, spec, equipped gear, and bag items (`CharacterExport.lua`)
- **Include item names** checkbox to optionally omit `names` arrays from the export (SavedVariables `includeGearNames`)
- Addon version shown under the window title
- Slash command `/mrc version` to print the addon version
- `## X-LastUpdated` TOC field (mirrored by README badge); `/mrc status` includes the last-updated date

### Changed
- Export output is a JSON-like object instead of two comma-separated lines

### Removed
- **Version** and **Character Info** buttons from the main window (use `/mrc version` and the title label instead)

## [0.2.0] - 2026-08-15

### Added
- Main in-game window (`ExporterWindow.lua`) with addon title header
- **Version** button that prints the current addon version to chat
- **Character Info** button that prints local date/time and character name to chat
- Slash commands `/mrc show` (also `ui`) and `/mrc hide` to open/close the window

## [0.1.0] - 2026-08-15

### Added
- Initial **mrc-exporter** addon for Wrath of the Lich King 3.3.5a (`Interface: 30300`)
- Slash commands `/mrc` and `/mrcexporter` with `help` and `status` subcommands
- SavedVariables store `MrcExporterDB` (default `enabled` flag)
- Load message in chat when the addon initializes

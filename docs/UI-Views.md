# UI view schemes

ASCII layouts for each window and content page. Update this file when a view changes. Pixel sizes live in [`UI-Sizes.md`](UI-Sizes.md) and the `UI` table in `ExporterWindow.lua`.

## Shell

Details-style plain panels: left menu, content page, status bar under both.

```text
[ Menu 170 ] 2px [ Content 520 x 480 ]
                 [ title bar 20      ]
                 [ page body         ]
[ addon name ] [ current version ] [ github repo link ]
```

Status bar:

| Block | In-game text |
|-------|----------------|
| addon name | Raidwise |
| current version | `v` + `Addon.version` |
| github repo link | `github.com/sergimax/Raidwise-addon` (click prints the full URL in chat) |

Menu tabs (top to bottom):

```text
[ Export gear and CDs ]
```

## Export gear and CDs

```text
[ short description ]
[ checkbox for including item names ]
[ export data button ] [ select all data button ]
[ short hint about copy ]
[ input for copy ]
```

| Block | In-game text / control |
|-------|------------------------|
| short description | “Export this character's gear, bags, and raid lockouts as JSON.” |
| checkbox | Include item names |
| export data button | **Export data** — fills the copy box |
| select all data button | **Select all** — highlights JSON for Ctrl+C (disabled until export) |
| short hint | Starts as “After export, press Ctrl+C to copy.” |
| input for copy | Scrollable JSON EditBox |

## Adding a view

1. Add a tab in `PAGES` in `ExporterWindow.lua`.
2. Paste a new `## Title` scheme here (same `[ block ]` style).
3. Implement the page and record sizes in `UI-Sizes.md`.

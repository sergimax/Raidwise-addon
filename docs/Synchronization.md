# Profile exchange

The **Export** and **Import** views support explicit Player–Player and Player–External
exchange. Guild/raid sharing is a broadcast request followed by individually
accepted whisper transfers; automatic guild replication is not implemented.

## Export and import views

- **Characters data export** creates copyable JSON for the complete saved character
  database. It does not select individual characters.
- **Character → Share** offers the same recipients for the open character.
  **Character database → Share database** shares the full saved database.
- In **Import**, paste compatible JSON and select **Review JSON** to prepare an
  external import.
- Incoming requests can be **received**, **cancelled**, or **ignored**. Receive
  downloads data only. Review the short list and totals, then **Apply changes**
  or **Cancel**. No import happens automatically.
- Ignore is persistent by character name across realms. The name input filters
  the ignored-character list; Previous/Next exposes additional entries. Use a
  row's **Unignore** button or type the name and choose **Unignore**. Legacy
  name/realm entries remain effective and are consolidated when edited. Incoming
  requests can also be disabled globally. Transport sender identities still use
  name and realm; only the ignore rule is name-based.
- Stop buttons cancel pending sending/receiving. Timeouts, cancellations and errors
  appear in the view. A sender without Raidwise does not answer the offer.

## Version 1 JSON contract

```json
{
  "format": "RaidwiseProfiles",
  "reportVersion": 1,
  "exportedAt": 1790000000,
  "characters": [
    {
      "guid": "0x0000000000000001",
      "name": "Example",
      "realm": "Realm",
      "class": "MAGE",
      "opinion": "positive",
      "tags": ["good_player"],
      "facts": [],
      "events": [],
      "links": [],
      "updatedAt": 1790000000
    }
  ]
}
```

`reportVersion` is independent of addon semver, other report formats and Gear
Check `schemaVersion`. Unknown versions are rejected before staging. Arrays must
be JSON arrays, even when empty. UTF-8 and escaped Unicode strings are supported.
`opinion` is `positive`, `neutral` or `negative`. Tags/facts/event types use the
catalog IDs in `PlayerHistory.lua`; limits match profile tag/fact controls.
Event entries contain `type`, numeric `eventAt`, and string `creatorId`. Links
are GUIDs, without Main/Alt designations. `updatedAt` is a nonnegative timestamp;
it is informational, not trusted for automatic overwrite decisions.

An optional `community` object contains the Karma value as numeric `positivePercent` in 0–100 and
an array of catalog `tags`. Only stored, non-mock Karma snapshots are exported.
Incoming claims are not independently authenticated or aggregated into consensus.

Never exported: private memos, automatic same-party events, event context, scan
data, encounter/change history, local Main preferences, mock Karma scores,
settings or ignore lists. Fields outside the whitelist are ignored on import.
Personal opinions are deliberately included in this explicit profile exchange.

## Merge and provenance

- Incoming data stays in memory until Apply; cancelling leaves SavedVariables intact.
- The review lists up to 12 characters, action, opinion, tag/fact/event/link counts
  and Karma value, plus totals for the entire payload.
- GUID and name/realm are matched. Conflicting GUID identities and duplicate
  identities within a payload are rejected or skipped, rather than overwriting.
- Locally customized profiles are protected as a whole. This is rechecked when
  Apply is clicked, so local edits made while the preview was open also win.
- New/imported profiles can be added/replaced on explicit Apply. Their source is
  `user` with the actual addon-message sender or `website` with `JSON` for pasted
  text. Payload claims cannot change this provenance. Notes and automatic
  encounter events are preserved; incoming user events replace imported events.
- Existing character groups and local Main choices are retained. Links are created
  only between accepted imported records without existing groups. References to
  characters outside that accepted set are not applied. A new group receives a
  local default Main; no remote Main preference is accepted. Linking imported
  characters does not overwrite their individual opinions.

## Transport and limits

Owner: `SyncTransport.lua`; wire prefix `RaidwiseSync1`, protocol version 1.

| Packet | Meaning |
|---|---|
| `O|id|1|bytes|characters|adler32` | Offer on WHISPER, GUILD or RAID |
| `A|id` | Receiver consents to download (WHISPER) |
| `D|id|index|chunk` | 1-based chunk sent by WHISPER only |
| `X|id` | Cancel/refuse/busy |

The sender snapshots intended recipients at offer time. Only those recipients
can accept. Data is bound to sender + transfer ID, and only accepted transfers
are assembled. Duplicate identical chunks are harmless; conflicting chunks,
wrong sizes/checksums and invalid payloads cannot stage an import. Adler-32 is
integrity checking, not a cryptographic signature. There is no Lua evaluation.

Limits: 256 KiB, 1,000 characters, 100 events/links per character, JSON depth 16
and 40,000 nodes. Exceeding a limit rejects the export/import without truncation.
Sending uses 180-byte chunks with a prefix-inclusive 255-byte cap and one packet
per 0.3 seconds across at most four simultaneous uploads. One download/review and
five pending requests are supported. Offers/transfers expire after 30 minutes;
sender offer cooldown is 30 seconds. Large group transfers may need another offer
after other recipients finish. Missing packets time out; retry is manual.

## Global Karma dataset

Global Karma is a separate, read-only dataset; it is not part of profile
exchange and is never included in a personal export. Version 1 uses the
`RaidwiseKarma` format with `datasetId`, numeric `revision`, `publishedAt`, and
a `characters` array. Each character record contains `character`,
`characterId`, `race`, `level` (1–80), `class`, and a 0–100 `rating`.

Pasted data is staged first. Applying it replaces the whole active dataset only
when its revision is greater than the installed revision, or when revisions are
equal and its publication timestamp is newer. Invalid, duplicate, older, or
equal data is rejected; no merge occurs. A later UI phase will expose this
review and its source metadata.

Pasted JSON is routed strictly by `format`: `RaidwiseProfiles` stages an
Exchange-profile import, while `RaidwiseKarma` stages the Global Karma dataset.
The addon-message transport accepts only `RaidwiseProfiles`; it cannot carry or
relay Global Karma. One review of either kind may be open at a time.

## Verification

`npm run check` covers JSON round trips/limits, privacy projection, version
rejection, consent, group/target routing, sender binding, chunk pacing, ignore,
timeouts, local-profile protection, links, provenance and input theme behavior.
The UI harness checks anchor cycles and the Sync page controls. Real-server
throttling, clipboard rendering, target/guild/raid delivery and two-client consent
still require an in-game test. Restart the client after installing new TOC modules.

Reference analysis: [Synchronization-Analysis.md](../____EXAMPLES/Synchronization-Analysis.md).

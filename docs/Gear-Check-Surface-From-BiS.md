# Gear Check — surface rules distilled from BiS lists

Reference extracted from:

- `examples/bis-list-mix.md` (guild / RU composite)
- `examples/bis-list-sources.md` (Warmane, Circle, Icy Veins, Titans, …)

**Purpose:** answer “what is *appropriate*” for class/spec so Gear Check can avoid false BAD/REPLACE.  
**Not purpose:** BiS ranking, upgrade paths, or “this item is best.” Spec §4 / §28 stay out of scope.

Sources often list **temporary offset pieces** (wrong armor type, better stats). Treat those as **acceptable**, not preferred.

Addon profile keys use WotLK talent tabs: `CLASSFILE-specTab` (e.g. `SHAMAN-2` = Enhancement).

---

## How to use this in code later

Suggested shape (not wired yet):

```text
SurfaceProfile {
  armor: { preferred[], acceptable[], discouraged[], forbidden[] }
  weapons: {
    preferredTypes[]          -- axe1h, sword2h, …
    setups[]                  -- e.g. "dw_1h", "2h", "1h_shield", "1h_oh", "2h_ranged"
  }
  trinkets: { allowedItemIds[] or allowedNames[] }   -- when trinket phase lands
  notes[]
}
```

Until trinket analysis ships, use **armor + weapon setups** to tighten `GearCheckProfiles.lua` only.

---

## 1. Armor types (item types)

### Native preferred (class)

| Class | Preferred | Forbidden (hard) |
|-------|-----------|------------------|
| Warrior, Paladin, Death Knight | plate | cloth |
| Hunter, Shaman | mail | plate*, cloth |
| Rogue, Druid | leather | plate, mail†, cloth‡ |
| Mage, Warlock, Priest | cloth | leather, mail, plate |

\* Plate on mail classes is wrong for BiS-era gear; keep forbidden.  
† Mail on leather classes: rare; keep discouraged/forbidden except if a list shows otherwise.  
‡ Cloth on leather healers: Disc/Resto sometimes use **cloth chest** in mix lists — treat cloth chest as **acceptable for Resto Druid / Disc-Holy Priest only**, not preferred.

### Offset / acceptable (from BiS lists)

Physical DPS lists routinely use **lower armor types** for wrist / hands / waist / feet / sometimes legs:

| Spec | Preferred | Also seen on lists (acceptable) |
|------|-----------|----------------------------------|
| Arms / Fury Warrior | plate | leather (bracers, gloves, belt, boots) |
| Ret Paladin | plate | leather (bracers, belt, gloves), mail |
| Unholy / Frost DK | plate | leather / mail offset pieces |
| Enhancement Shaman | mail | leather bracers/boots; hunter-mail gloves/belt |
| Hunter (all) | mail | leather wrists/belt/boots/legs |
| Holy Paladin | plate | leather belt/legs; some mail |
| Feral Druid | leather | (stays leather; no plate) |
| Tanks (Prot Warr / Prot Pala / Blood DK) | plate | **almost no offset** — keep mail/leather discouraged |

### Implementation hint

Current profiles already use `A_PLATE_DPS` for Ret. Extend the same idea to:

- Fury / Arms → `A_PLATE_DPS` (or plate preferred + leather/mail acceptable)
- Enhancement → mail preferred + leather acceptable (already close)
- Hunter → mail preferred + leather acceptable
- Blood / Prot → keep `A_PLATE_TANK` (strict)

---

## 2. Weapon setups (by spec)

Types use Gear Check tokens: `axe1h`, `axe2h`, `sword1h`, `sword2h`, `mace1h`, `mace2h`, `polearm`, `staff`, `fist`, `dagger`, `shield`, `offhand`, `bow`, `gun`, `crossbow`, `thrown`, `wand`.

| Spec key | Typical setup | Preferred types (from lists) | Notes |
|----------|---------------|------------------------------|-------|
| `WARRIOR-1` Arms | `2h` + ranged | `axe2h`, `sword2h`, `polearm`; ranged `bow`/`gun` | Shadowmourne / Glorenzelg + Fal'inrush |
| `WARRIOR-2` Fury | `dw_2h` (Titan’s Grip) + ranged | `axe2h`, `sword2h`; ranged `bow` | Dual 2H — **not** classic DW 1H only |
| `WARRIOR-3` Prot | `1h_shield` + ranged | `axe1h`, `mace1h`, `sword1h`, `shield`; `gun`/`bow` | |
| `PALADIN-1` Holy | `1h_shield` | `mace1h`, `sword1h`, `shield` | Terenas / Bloodsurge / Val'anyr |
| `PALADIN-2` Prot | `1h_shield` | same as Prot Warrior MH + shield | |
| `PALADIN-3` Ret | `2h` | `axe2h`, `mace2h`, `polearm`, `sword2h` | Shadowmourne / Bloodvenom / Oathbinder |
| `HUNTER-*` | `2h` + ranged | `polearm`, `axe2h`, `staff`; `bow`/`gun`/`crossbow` | Oathbinder + Fal'inrush |
| `ROGUE-1` Assassination | `dw_dagger` + ranged | `dagger`; `bow`/`thrown` | |
| `ROGUE-2` Combat | `dw_1h` + ranged | `axe1h`, `fist`, `sword1h`; `bow` | Havoc’s Call + Scourge axe |
| `ROGUE-3` Subtlety | `dw_1h` or MH 1H + ranged | `axe1h`, `sword1h`, `dagger`; `bow` | |
| `PRIEST-1/2` Disc/Holy | `1h_oh` or `staff` | `mace1h`, `staff`, `offhand`; wand optional | Archus staff on Holy |
| `PRIEST-3` Shadow | `1h_oh` + wand | `mace1h`/`sword1h`, `offhand`, `wand` | |
| `DEATHKNIGHT-1` Blood | `2h` | `sword2h`, `axe2h`, `mace2h`, `polearm` | Glorenzelg |
| `DEATHKNIGHT-2` Frost | `dw_1h` | `axe1h`, `sword1h`, `mace1h` | Dual Havoc’s Call |
| `DEATHKNIGHT-3` Unholy | `2h` | `axe2h`, `sword2h`, … | Shadowmourne |
| `SHAMAN-1` Elemental | `1h_shield` | `mace1h`, `dagger`, `shield`, `staff` | |
| `SHAMAN-2` Enhancement | `dw_1h` (AP) or MH mace + OH axe (SP lists) | `axe1h`, `mace1h`, `fist` | Dual Havoc’s Call on AP lists |
| `SHAMAN-3` Restoration | `1h_shield` | `mace1h`, `shield` | Val'anyr / Terenas |
| `MAGE-*` / `WARLOCK-*` | `1h_oh` + wand | `sword1h`, `dagger`, `staff`, `offhand`, `wand` | Bloodsurge + Shadowsilk Spindle |
| `DRUID-1` Balance | `1h_oh` or staff | `mace1h`, `staff`, `offhand` | |
| `DRUID-2` Feral | `2h` | `polearm`, `staff`, `mace2h` | Oathbinder |
| `DRUID-3` Restoration | `1h_oh` or staff | `mace1h`, `staff`, `offhand` | |

### Gaps vs current addon logic

- **Fury:** profiles prefer DW **1H**; BiS is **dual 2H**. Prefer `axe2h`/`sword2h` for Fury (keep 1H acceptable).
- **Weapon combinations** (spec §12) still missing: flag empty OH on Fury/Enh/Frost; flag 2H+shield; etc.
- Relics (idol/libram/totem/sigil) stay **ignored** per product decision; lists include them but Gear Check does not score them.

---

## 3. Trinkets (allow pools by role / spec)

Canonical **English** names (RU aliases in parentheses). Use as **allowed** sets when trinket phase starts — presence in BiS ⇒ not inappropriate; absence ≠ BAD.

### Physical melee DPS

`WARRIOR-1/2`, `PALADIN-3`, `ROGUE-*`, `DEATHKNIGHT-2/3`, `DRUID-2`, `SHAMAN-2` (AP)

| Item | Notes |
|------|--------|
| Deathbringer's Will (Воля Смертоносного) | Near-universal |
| Sharpened Twilight Scale (Заострённая сумеречная чешуя) | Near-universal |
| Tiny Abomination in a Jar (Миниатюрное поганище в колбе) | Ret |
| Herkuml War Token (Геркумлийский боевой знак) | Enh badge option |

Enhancement **SP** lists (Icy Veins): also caster trinkets below.

### Hunter

| Item |
|------|
| Deathbringer's Will |
| Sharpened Twilight Scale |

### Caster DPS

`MAGE-*`, `WARLOCK-*`, `PRIEST-3`, `SHAMAN-1`, `DRUID-1`

| Item | Notes |
|------|--------|
| Charred Twilight Scale (Обугленная сумеречная чешуя) | |
| Phylactery of the Nameless Lich (Талисман безымянного лича) | |
| Dislodged Foreign Object (Объект из другого измерения) | Arcane often |

### Healers

`PRIEST-1/2`, `PALADIN-1`, `SHAMAN-3`, `DRUID-3`

| Item | Notes |
|------|--------|
| Glowing Twilight Scale (Светящаяся сумеречная чешуя) | Primary |
| Althor's Abacus (Счёты Алтора) | |
| Solace of the Fallen / Defeated (Утешение павших) | ToC |
| Talisman of Resurgence (Талисман восстановления) | Holy Pal badge |
| Meteorite Crystal (Метеоритный кристалл) | Holy Pal Ulduar |
| Charred Twilight Scale | Sometimes as 2nd on Holy Pal |

### Tanks

`WARRIOR-3`, `PALADIN-2`, `DEATHKNIGHT-1`

| Item |
|------|
| Sindragosa's Flawless Fang (Безупречный клык Синдрагосы) |
| Petrified Twilight Scale (Окаменелая сумеречная чешуя) |
| Corroded Skeleton Key (Проржавевший костяной ключ) |
| Satrina's Impenetrable Scarab (Упрямый скарабей Сатрины) |

### Cross-role caution

Do **not** mark Deathbringer's Will BAD on a healer, or Glowing Scale BAD on a hunter — wrong role is a soft/hard issue only if the **stat profile** already forbids those stats. Prefer: trinket not in allowlist → `TRINKET_NOT_PREFERRED` (soft) or not-checkable until catalogued; never invent BiS.

---

## 4. Per-spec quick matrix

| Spec | Armor preferred | Offset OK? | Weapons | Trinket pool |
|------|-----------------|------------|---------|--------------|
| Arms | plate | leather | 2H + bow/gun | phys melee |
| Fury | plate | leather | **DW 2H** + bow | phys melee |
| Prot Warrior | plate | no | 1H + shield + gun | tank |
| Holy Paladin | plate | leather/mail | 1H + shield | healer (+ Charred ok) |
| Prot Paladin | plate | no | 1H + shield | tank |
| Ret | plate | leather/mail | 2H | phys + Tiny Abom |
| Hunter BM/MM/SV | mail | leather | 2H + bow/gun | phys hunter |
| Assassination | leather | — | DW dagger + ranged | phys melee |
| Combat | leather | — | DW 1H axe + bow | phys melee |
| Subtlety | leather | — | 1H + bow | phys melee |
| Disc / Holy Priest | cloth | cloth only | 1H+OH / staff | healer |
| Shadow Priest | cloth | — | 1H+OH+wand | caster |
| Blood DK | plate | no | 2H | tank |
| Frost DK | plate | leather | DW 1H | phys melee |
| Unholy DK | plate | leather | 2H | phys melee |
| Elemental | mail | — | 1H + shield | caster |
| Enhancement | mail | leather | DW 1H (axe/mace) | phys (+ caster on SP) |
| Resto Shaman | mail | — | 1H + shield | healer |
| Mage / Lock | cloth | — | 1H+OH+wand | caster |
| Balance | leather | — | 1H+OH / staff | caster |
| Feral | leather | — | 2H polearm | phys melee |
| Resto Druid | leather | cloth chest seen | 1H+OH / staff | healer |

---

## 5. Source coverage holes

Empty or thin sections in the example files (do not invent BiS):

- Mix: Arms, BM Hunter, Survival, Assassination, Subtlety, Frost Mage, Destruction, Enh SP subsection
- Prefer `bis-list-sources.md` Icy Veins / Warmane blocks for those specs

---

## 6. Suggested follow-ups (Gear Check)

1. **Profiles:** Fury weapons → prefer 2H; Arms/Fury/Hunter/Enh armor → leather acceptable; tank profiles stay strict.
2. **Weapon combos:** enforce setups from §2 (empty OH on DW specs, etc.).
3. **Trinkets:** new catalog + `allowed` sets from §3 when PLANNED → CHECKED.
4. Keep this file updated when BiS example lists change; do not auto-score “closeness to BiS.”

Sources: `examples/bis-list-mix.md`, `examples/bis-list-sources.md`.

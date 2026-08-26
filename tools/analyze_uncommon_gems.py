# Analyze uncommon Northrend socket gems in AtlasLoot vs Raidwise catalog.
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
crafting = (root / "examples" / "AtlasLoot_Crafting" / "crafting.lua").read_text(
    encoding="utf-8", errors="replace"
)
catalog = (root / "Raidwise" / "GearCheckCatalog.lua").read_text(
    encoding="utf-8", errors="replace"
)

SOCKET_PREFIXES = (
    "JewelRed",
    "JewelBlue",
    "JewelYellow",
    "JewelGreen",
    "JewelOrange",
    "JewelPurple",
)

# Uncommon Northrend base stones (q2 cuts)
UNCOMMON_MARKERS = (
    "Bloodstone",
    "Sun Crystal",
    "Chalcedony",
    "Huge Citrine",
    "Shadow Crystal",
    "Dark Jade",
)

# Name prefix -> (color, stats) for uncommon Northrend cuts
# Magnitudes are the standard q2 values (~half of rare / ~40% of epic ratings).
STAT_BY_PREFIX = {
    # red Bloodstone
    "Bold": ("red", {"strength": 12}),
    "Bright": ("red", {"attackPower": 24}),
    "Delicate": ("red", {"agility": 12}),
    "Flashing": ("red", {"parryRating": 12}),
    "Fractured": ("red", {"armorPenetration": 12}),
    "Precise": ("red", {"expertiseRating": 12}),
    "Runed": ("red", {"spellPower": 14}),
    "Subtle": ("red", {"dodgeRating": 12}),
    # blue Chalcedony
    "Solid": ("blue", {"stamina": 18}),
    "Sparkling": ("blue", {"spirit": 12}),
    "Lustrous": ("blue", {"mp5": 5}),
    "Stormy": ("blue", {"spellPenetration": 15}),
    # yellow Sun Crystal
    "Brilliant": ("yellow", {"intellect": 12}),
    "Smooth": ("yellow", {"critRating": 12}),
    "Rigid": ("yellow", {"hitRating": 12}),
    "Thick": ("yellow", {"defenseRating": 12}),
    "Mystic": ("yellow", {"resilience": 12}),
    "Quick": ("yellow", {"hasteRating": 12}),
    # purple Shadow Crystal
    "Sovereign": ("purple", {"strength": 6, "stamina": 9}),
    "Shifting": ("purple", {"agility": 6, "stamina": 9}),
    "Tenuous": ("purple", {"agility": 6, "mp5": 3}),
    "Glowing": ("purple", {"spellPower": 7, "stamina": 9}),
    "Purified": ("purple", {"spellPower": 7, "spirit": 6}),
    "Royal": ("purple", {"spellPower": 7, "mp5": 3}),
    "Mysterious": ("purple", {"spellPower": 7, "spellPenetration": 8}),
    "Balanced": ("purple", {"attackPower": 12, "stamina": 9}),
    "Infused": ("purple", {"attackPower": 12, "mp5": 3}),
    "Regal": ("purple", {"dodgeRating": 6, "stamina": 9}),
    "Defender's": ("purple", {"parryRating": 6, "stamina": 9}),
    "Puissant": ("purple", {"armorPenetration": 6, "stamina": 9}),
    "Guardian's": ("purple", {"expertiseRating": 6, "stamina": 9}),
    # orange Huge Citrine
    "Accurate": ("orange", {"expertiseRating": 6, "hitRating": 6}),
    "Champion's": ("orange", {"strength": 6, "defenseRating": 6}),
    "Deadly": ("orange", {"agility": 6, "critRating": 6}),
    "Deft": ("orange", {"agility": 6, "hasteRating": 6}),
    "Durable": ("orange", {"spellPower": 7, "resilience": 6}),
    "Empowered": ("orange", {"attackPower": 12, "resilience": 6}),
    "Etched": ("orange", {"strength": 6, "hitRating": 6}),
    "Fierce": ("orange", {"strength": 6, "hasteRating": 6}),
    "Glimmering": ("orange", {"parryRating": 6, "defenseRating": 6}),
    "Glinting": ("orange", {"agility": 6, "hitRating": 6}),
    "Inscribed": ("orange", {"strength": 6, "critRating": 6}),
    "Lucent": ("orange", {"agility": 6, "resilience": 6}),
    "Luminous": ("orange", {"spellPower": 7, "intellect": 6}),
    "Potent": ("orange", {"spellPower": 7, "critRating": 6}),
    "Pristine": ("orange", {"attackPower": 12, "hitRating": 6}),
    "Reckless": ("orange", {"spellPower": 7, "hasteRating": 6}),
    "Resolute": ("orange", {"expertiseRating": 6, "defenseRating": 6}),
    "Resplendent": ("orange", {"strength": 6, "resilience": 6}),
    "Stalwart": ("orange", {"dodgeRating": 6, "defenseRating": 6}),
    "Stark": ("orange", {"attackPower": 12, "hasteRating": 6}),
    "Veiled": ("orange", {"spellPower": 7, "hitRating": 6}),
    "Wicked": ("orange", {"attackPower": 12, "critRating": 6}),
    # green Dark Jade
    "Timeless": ("green", {"intellect": 6, "stamina": 9}),
    "Jagged": ("green", {"critRating": 6, "stamina": 9}),
    "Vivid": ("green", {"hitRating": 6, "stamina": 9}),
    "Enduring": ("green", {"defenseRating": 6, "stamina": 9}),
    "Steady": ("green", {"resilience": 6, "stamina": 9}),
    "Forceful": ("green", {"hasteRating": 6, "stamina": 9}),
    "Seer's": ("green", {"intellect": 6, "spirit": 6}),
    "Misty": ("green", {"critRating": 6, "spirit": 6}),
    "Shining": ("green", {"hitRating": 6, "spirit": 6}),
    "Turbid": ("green", {"resilience": 6, "spirit": 6}),
    "Intricate": ("green", {"hasteRating": 6, "spirit": 6}),
    "Dazzling": ("green", {"intellect": 6, "mp5": 3}),
    "Sundered": ("green", {"critRating": 6, "mp5": 3}),
    "Lambent": ("green", {"hitRating": 6, "mp5": 3}),
    "Opaque": ("green", {"resilience": 6, "mp5": 3}),
    "Energized": ("green", {"hasteRating": 6, "mp5": 3}),
    "Radiant": ("green", {"critRating": 6, "spellPenetration": 8}),
    "Tense": ("green", {"hitRating": 6, "spellPenetration": 8}),
    "Shattered": ("green", {"hasteRating": 6, "spellPenetration": 8}),
}

cur = None
found = []
for line in crafting.splitlines():
    m = re.search(r'AtlasLoot_Data\["(Jewel[^"]+)"\]', line)
    if m:
        cur = m.group(1)
        continue
    if not cur or not any(cur.startswith(p) for p in SOCKET_PREFIXES):
        continue
    if line.strip() == "}":
        cur = None
        continue
    item = re.search(
        r'\{\s*\d+,\s*"[^"]+",\s*"?(\d+)"?,\s*"=q([12])=([^"]+)"',
        line,
    )
    if not item:
        continue
    iid, q, name = int(item.group(1)), int(item.group(2)), item.group(3)
    if not any(marker in name for marker in UNCOMMON_MARKERS):
        continue
    prefix = name.split()[0]
    for multi in ("Defender's", "Champion's", "Guardian's", "Seer's"):
        if name.startswith(multi):
            prefix = multi
            break
    mapped = STAT_BY_PREFIX.get(prefix)
    found.append(
        {
            "id": iid,
            "q": q,
            "name": name,
            "table": cur,
            "prefix": prefix,
            "mapped": mapped,
        }
    )

gems_block = re.search(r"local GEMS = \{(.*?)\n\}", catalog, re.S)
catalog_ids = set()
if gems_block:
    for m in re.finditer(r"\[(\d+)\]", gems_block.group(1)):
        catalog_ids.add(int(m.group(1)))

by_stone = {}
for g in found:
    stone = next(s for s in UNCOMMON_MARKERS if s in g["name"])
    by_stone.setdefault(stone, []).append(g)

in_catalog = [g for g in found if g["id"] in catalog_ids]
missing = [g for g in found if g["id"] not in catalog_ids]
unmapped = [g for g in found if g["mapped"] is None]

out = root / "tools" / "uncommon-gem-analysis.txt"
lines = []
lines.append("=== Uncommon Northrend socket gems (AtlasLoot) ===")
lines.append(f"total={len(found)} in_catalog={len(in_catalog)} missing={len(missing)} unmapped_prefix={len(unmapped)}")
lines.append("")
for stone in UNCOMMON_MARKERS:
    rows = by_stone.get(stone, [])
    lines.append(f"--- {stone}: {len(rows)} ---")
    for g in sorted(rows, key=lambda x: x["id"]):
        status = "IN_CATALOG" if g["id"] in catalog_ids else "MISSING"
        map_s = "OK" if g["mapped"] else f"NO_MAP({g['prefix']})"
        color = g["mapped"][0] if g["mapped"] else "?"
        lines.append(f"{g['id']}\tq{g['q']}\t{g['name']}\t{status}\t{map_s}\tcolor={color}")
    lines.append("")

# Also list quality distribution across all Jewel socket tables for context
q_counts = {1: 0, 2: 0, 3: 0, 4: 0}
cur = None
for line in crafting.splitlines():
    m = re.search(r'AtlasLoot_Data\["(Jewel[^"]+)"\]', line)
    if m:
        cur = m.group(1)
        continue
    if not cur or not any(cur.startswith(p) for p in SOCKET_PREFIXES):
        continue
    if line.strip() == "}":
        cur = None
        continue
    item = re.search(
        r'\{\s*\d+,\s*"[^"]+",\s*"?(\d+)"?,\s*"=q([1-4])=([^"]+)"',
        line,
    )
    if item:
        q_counts[int(item.group(2))] += 1

lines.append("=== All AtlasLoot socket-table quality counts ===")
for q in (4, 3, 2, 1):
    lines.append(f"q{q}: {q_counts[q]}")

# Behavior note for rules
lines.append("")
lines.append("=== Gear-check behavior if seeded ===")
lines.append("maxLevel=false -> soft GEM_LOWER_LEVEL (replace with epic)")
lines.append("unknown id     -> info GEM_NOT_CHECKABLE (no replace pressure)")
lines.append("stats still evaluated for GEM_BAD_STAT if catalog has stats")

out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(out.read_text(encoding="utf-8"))

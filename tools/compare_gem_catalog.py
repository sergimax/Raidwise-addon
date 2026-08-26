# Compare AtlasLoot Northrend epic socket gems vs Raidwise GearCheckCatalog GEMS.
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
crafting = (root / "examples" / "AtlasLoot_Crafting" / "crafting.lua").read_text(
    encoding="utf-8", errors="replace"
)
catalog = (root / "Raidwise" / "GearCheckCatalog.lua").read_text(
    encoding="utf-8", errors="replace"
)

SOCKET_TABLES = {
    "JewelRed",
    "JewelBlue",
    "JewelYellow",
    "JewelGreen",
    "JewelOrange",
    "JewelPurple",
    "JewelMeta",
    "JewelPrismatic",
    "JewelDragonsEye",
}

current = None
atlas = {}  # id -> (quality, name, table)

for line in crafting.splitlines():
    m = re.search(r'AtlasLoot_Data\["(Jewel[^"]+)"\]', line)
    if m:
        current = m.group(1)
        continue
    if current is None:
        continue
    if line.strip() == "}":
        current = None
        continue
    prefix = re.match(r"(Jewel[A-Za-z]+)", current)
    if not prefix or prefix.group(1) not in SOCKET_TABLES:
        continue
    item = re.search(
        r'\{\s*\d+,\s*"[^"]+",\s*"?(\d+)"?,\s*"=q([1-4])=([^"]+)"',
        line,
    )
    if not item:
        continue
    iid, quality, name = int(item.group(1)), int(item.group(2)), item.group(3)
    if name in ("Dragon's Eye",) or name.startswith("Design:"):
        continue
    atlas[iid] = (quality, name, current)

# Parse catalog GEMS table entries: [id] = { ... }
gems_block = re.search(r"local GEMS = \{(.*?)\n\}", catalog, re.S)
catalog_ids = set()
catalog_meta = {}
if gems_block:
    for m in re.finditer(r"\[(\d+)\]\s*=\s*\{([^}]*)\}", gems_block.group(1)):
        iid = int(m.group(1))
        body = m.group(2)
        catalog_ids.add(iid)
        max_level = "maxLevel = true" in body
        color_m = re.search(r'color\s*=\s*"([^"]+)"', body)
        catalog_meta[iid] = {
            "maxLevel": max_level,
            "color": color_m.group(1) if color_m else "?",
            "body": body.strip(),
        }

# Epic Northrend cuts are q4 and named Cardinal Ruby / Ametrine / Dreadstone /
# Eye of Zul / King's Amber / Majestic Zircon / Autumn's Glow? Wait yellows:
# Epic yellow = King's Amber, epic blue = Majestic Zircon, epic red = Cardinal Ruby
EPIC_NAME_MARKERS = (
    "Cardinal Ruby",
    "Ametrine",
    "Dreadstone",
    "Eye of Zul",
    "King's Amber",
    "Majestic Zircon",
    "Dragon's Eye",
    "Nightmare Tear",
    "Earthsiege Diamond",
    "Skyflare Diamond",
)

def is_wotlk_epic_socket(name, quality):
    if quality != 4:
        # Nightmare Tear is q3 prismatic in some DBs but catalog has it as epic-equivalent
        if "Nightmare Tear" in name:
            return True
        return False
    return any(marker in name for marker in EPIC_NAME_MARKERS)

epic_atlas = {
    iid: info for iid, info in atlas.items() if is_wotlk_epic_socket(info[0] and info[1], info[0])
}
# fix: info is (quality, name, table)
epic_atlas = {
    iid: (q, name, table)
    for iid, (q, name, table) in atlas.items()
    if is_wotlk_epic_socket(name, q)
}

missing = sorted(set(epic_atlas) - catalog_ids)
extra = sorted(catalog_ids - set(atlas))  # in catalog but not in any socket AtlasLoot table
present_epic = sorted(set(epic_atlas) & catalog_ids)

# Rare Northrend (q3) for completeness report — Scarlet Ruby, Monarch Topaz, etc.
RARE_MARKERS = (
    "Scarlet Ruby",
    "Monarch Topaz",
    "Twilight Opal",
    "Forest Emerald",
    "Autumn's Glow",
    "Sky Sapphire",
    "Bloodstone",
    "Sun Crystal",
    "Chalcedony",
    "Huge Citrine",
    "Shadow Crystal",
    "Dark Jade",
)

rare_atlas = {
    iid: (q, name, table)
    for iid, (q, name, table) in atlas.items()
    if q == 3 and any(m in name for m in RARE_MARKERS)
}
rare_in_catalog = sorted(set(rare_atlas) & catalog_ids)
rare_missing = sorted(set(rare_atlas) - catalog_ids)

out = root / "tools" / "gem-catalog-diff.txt"
lines = []
lines.append(f"AtlasLoot socket gems total: {len(atlas)}")
lines.append(f"WotLK epic socket gems (AtlasLoot): {len(epic_atlas)}")
lines.append(f"Catalog GEMS entries: {len(catalog_ids)}")
lines.append(f"Epic present in catalog: {len(present_epic)}")
lines.append(f"Epic MISSING from catalog: {len(missing)}")
lines.append(f"Rare Northrend in AtlasLoot: {len(rare_atlas)}")
lines.append(f"Rare present in catalog: {len(rare_in_catalog)}")
lines.append(f"Rare MISSING from catalog: {len(rare_missing)}")
lines.append("")
lines.append("=== EPIC MISSING ===")
for iid in missing:
    q, name, table = epic_atlas[iid]
    lines.append(f"{iid}\tq{q}\t{name}\t({table})")
lines.append("")
lines.append("=== EPIC PRESENT (sample check) ===")
for iid in present_epic:
    q, name, table = epic_atlas[iid]
    meta = catalog_meta.get(iid, {})
    lines.append(f"{iid}\t{name}\tmaxLevel={meta.get('maxLevel')}\tcolor={meta.get('color')}")
lines.append("")
lines.append("=== RARE MISSING (first 80) ===")
for iid in rare_missing[:80]:
    q, name, table = rare_atlas[iid]
    lines.append(f"{iid}\tq{q}\t{name}\t({table})")
if len(rare_missing) > 80:
    lines.append(f"... +{len(rare_missing)-80} more")
lines.append("")
lines.append("=== CATALOG IDS NOT IN ATLAS SOCKET TABLES ===")
for iid in extra:
    meta = catalog_meta[iid]
    lines.append(f"{iid}\tmaxLevel={meta['maxLevel']}\tcolor={meta['color']}")

out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(out.read_text(encoding="utf-8")[:6000])
print(f"\n... full report: {out}")

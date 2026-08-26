# Scrape uncommon Northrend gem tooltips and emit catalog seeds.
import json
import re
import time
import urllib.request
from pathlib import Path

UA = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"}

# From AtlasLoot uncommon analysis
IDS = [
    # Bloodstone
    39900, 39905, 39906, 39907, 39908, 39909, 39910, 39911,
    # Sun Crystal
    39912, 39914, 39915, 39916, 39917, 39918,
    # Chalcedony
    39919, 39920, 39927, 39932,
    # Shadow Crystal
    39933, 39934, 39935, 39936, 39937, 39938, 39939, 39940,
    39941, 39942, 39943, 39944, 39945,
    # Huge Citrine
    39946, 39947, 39948, 39949, 39950, 39951, 39952, 39953,
    39954, 39955, 39956, 39957, 39958, 39959, 39960, 39961,
    39962, 39963, 39964, 39965, 39966, 39967,
    # Dark Jade
    39968, 39974, 39975, 39976, 39977, 39978, 39979, 39980,
    39981, 39982, 39983, 39984, 39985, 39986, 39988, 39989,
    39990, 39991, 39992,
]

STAT_PATTERNS = [
    (r"\+(\d+)\s+Strength", "strength"),
    (r"\+(\d+)\s+Agility", "agility"),
    (r"\+(\d+)\s+Stamina", "stamina"),
    (r"\+(\d+)\s+Intellect", "intellect"),
    (r"\+(\d+)\s+Spirit", "spirit"),
    (r"\+(\d+)\s+Attack Power", "attackPower"),
    (r"\+(\d+)\s+Spell Power", "spellPower"),
    (r"\+(\d+)\s+Critical Strike Rating", "critRating"),
    (r"\+(\d+)\s+Hit Rating", "hitRating"),
    (r"\+(\d+)\s+Haste Rating", "hasteRating"),
    (r"\+(\d+)\s+Expertise Rating", "expertiseRating"),
    (r"\+(\d+)\s+Armor Penetration Rating", "armorPenetration"),
    (r"\+(\d+)\s+Defense Rating", "defenseRating"),
    (r"\+(\d+)\s+Dodge Rating", "dodgeRating"),
    (r"\+(\d+)\s+Parry Rating", "parryRating"),
    (r"\+(\d+)\s+Resilience Rating", "resilience"),
    (r"\+(\d+)\s+Spell Penetration", "spellPenetration"),
    (r"\+(\d+)\s+Mana every 5 seconds", "mp5"),
]

COLOR_BY_STONE = {
    "Bloodstone": "red",
    "Sun Crystal": "yellow",
    "Chalcedony": "blue",
    "Huge Citrine": "orange",
    "Shadow Crystal": "purple",
    "Dark Jade": "green",
}


def fetch_tooltip(iid: int) -> tuple[str, str]:
    # Prefer Cavern of Time HTML
    url = f"https://wotlk.cavernoftime.com/item={iid}"
    req = urllib.request.Request(url, headers=UA)
    try:
        html = urllib.request.urlopen(req, timeout=25).read().decode("utf-8", "replace")
        text = re.sub(r"<[^>]+>", " ", html)
        text = re.sub(r"\s+", " ", text)
        m = re.search(
            r"([A-Za-z']+(?:'s)? (?:Bloodstone|Sun Crystal|Chalcedony|Huge Citrine|Shadow Crystal|Dark Jade))"
            r"\s*\+([^I]+?)\s*Item Level",
            text,
        )
        if m:
            return m.group(1).strip(), ("+" + m.group(2).strip())
    except Exception:
        pass

    # Fallback Wowhead tooltip JSON
    url2 = f"https://nether.wowhead.com/wotlk/tooltip/item/{iid}"
    req2 = urllib.request.Request(url2, headers=UA)
    raw = urllib.request.urlopen(req2, timeout=25).read().decode("utf-8", "replace")
    data = json.loads(raw)
    name = data.get("name", "?")
    tip = re.sub(r"<[^>]+>", " ", data.get("tooltip", ""))
    tip = re.sub(r"\s+", " ", tip)
    return name, tip


def parse_stats(blob: str) -> dict:
    stats = {}
    for pattern, key in STAT_PATTERNS:
        m = re.search(pattern, blob, re.I)
        if m:
            stats[key] = int(m.group(1))
    return stats


def color_for(name: str) -> str:
    for stone, color in COLOR_BY_STONE.items():
        if stone in name:
            return color
    return "?"


rows = []
errors = []
for iid in IDS:
    try:
        name, blob = fetch_tooltip(iid)
        stats = parse_stats(blob)
        if not stats:
            errors.append(f"{iid}\tNO_STATS\t{name}\t{blob[:180]}")
        rows.append((iid, name, color_for(name), stats, blob))
        time.sleep(0.05)
    except Exception as exc:
        errors.append(f"{iid}\tERROR\t{exc}")
        rows.append((iid, "?", "?", {}, str(exc)))

root = Path(__file__).resolve().parents[1]
raw_out = root / "tools" / "uncommon-gem-stats-raw.txt"
raw_lines = []
for iid, name, color, stats, blob in rows:
    raw_lines.append(f"{iid}\t{name}\t{color}\t{stats}\t{blob[:160]}")
raw_out.write_text("\n".join(raw_lines) + "\n", encoding="utf-8")

seed_out = root / "tools" / "uncommon-gem-seeds.lua"
seed_lines = [
    "\t-- Uncommon Northrend (maxLevel false) — tooltip-verified Bloodstone/Sun/Chalcedony/Citrine/Shadow/Dark Jade"
]
ok = 0
for iid, name, color, stats, _ in sorted(rows, key=lambda r: r[0]):
    if not stats or color == "?":
        seed_lines.append(f"\t-- TODO {iid} {name} color={color} stats={stats}")
        continue
    parts = ", ".join(f"{k} = {v}" for k, v in stats.items())
    seed_lines.append(
        f'\t[{iid}] = {{ maxLevel = false, color = "{color}", stats = {{ {parts} }} }}, -- {name}'
    )
    ok += 1
seed_out.write_text("\n".join(seed_lines) + "\n", encoding="utf-8")

err_out = root / "tools" / "uncommon-gem-stats-errors.txt"
err_out.write_text("\n".join(errors) + ("\n" if errors else ""), encoding="utf-8")

print(f"ok={ok}/{len(IDS)} errors={len(errors)}")
print(f"wrote {seed_out}")
if errors:
    print("ERRORS:")
    print("\n".join(errors[:20]))

# Build rare Northrend gem seed list from AtlasLoot names + known stat map.
import re
from pathlib import Path

crafting = Path(
    r"c:\Users\ififo\repos\Raidwise-addon\examples\AtlasLoot_Crafting\crafting.lua"
).read_text(encoding="utf-8", errors="replace")

SOCKET = ("JewelRed", "JewelBlue", "JewelYellow", "JewelGreen", "JewelOrange", "JewelPurple")
RARE_MARKERS = (
    "Scarlet Ruby",
    "Monarch Topaz",
    "Twilight Opal",
    "Forest Emerald",
    "Autumn's Glow",
    "Sky Sapphire",
)

# Name prefix -> (color, stats) for rare Northrend cuts (3.3.5a tooltips)
# Values are the standard rare magnitudes.
STAT_BY_PREFIX = {
    # red Scarlet Ruby
    "Bold": ("red", {"strength": 16}),
    "Bright": ("red", {"attackPower": 32}),
    "Delicate": ("red", {"agility": 16}),
    "Flashing": ("red", {"parryRating": 16}),
    "Fractured": ("red", {"armorPenetration": 16}),
    "Precise": ("red", {"expertiseRating": 16}),
    "Runed": ("red", {"spellPower": 19}),
    "Subtle": ("red", {"dodgeRating": 16}),
    # blue Sky Sapphire
    "Solid": ("blue", {"stamina": 24}),
    "Sparkling": ("blue", {"spirit": 16}),
    "Lustrous": ("blue", {"mp5": 8}),
    "Stormy": ("blue", {"spellPenetration": 20}),
    # yellow Autumn's Glow
    "Brilliant": ("yellow", {"intellect": 16}),
    "Smooth": ("yellow", {"critRating": 16}),
    "Rigid": ("yellow", {"hitRating": 16}),
    "Thick": ("yellow", {"defenseRating": 16}),
    "Mystic": ("yellow", {"resilience": 16}),
    "Quick": ("yellow", {"hasteRating": 16}),
    # purple Twilight Opal
    "Sovereign": ("purple", {"strength": 8, "stamina": 12}),
    "Shifting": ("purple", {"agility": 8, "stamina": 12}),
    "Tenuous": ("purple", {"agility": 8, "mp5": 4}),
    "Glowing": ("purple", {"spellPower": 9, "stamina": 12}),
    "Purified": ("purple", {"spellPower": 9, "spirit": 8}),
    "Royal": ("purple", {"spellPower": 9, "mp5": 4}),
    "Mysterious": ("purple", {"spellPower": 9, "spellPenetration": 10}),
    "Balanced": ("purple", {"attackPower": 16, "stamina": 12}),
    "Infused": ("purple", {"attackPower": 16, "mp5": 4}),
    "Regal": ("purple", {"dodgeRating": 8, "stamina": 12}),
    "Defender's": ("purple", {"parryRating": 8, "stamina": 12}),
    "Puissant": ("purple", {"armorPenetration": 8, "stamina": 12}),
    "Guardian's": ("purple", {"expertiseRating": 8, "stamina": 12}),
    # orange Monarch Topaz
    "Accurate": ("orange", {"expertiseRating": 8, "hitRating": 8}),
    "Champion's": ("orange", {"strength": 8, "defenseRating": 8}),
    "Deadly": ("orange", {"agility": 8, "critRating": 8}),
    "Deft": ("orange", {"agility": 8, "hasteRating": 8}),
    "Durable": ("orange", {"spellPower": 9, "resilience": 8}),
    "Empowered": ("orange", {"attackPower": 16, "resilience": 8}),
    "Etched": ("orange", {"strength": 8, "hitRating": 8}),
    "Fierce": ("orange", {"strength": 8, "hasteRating": 8}),
    "Glimmering": ("orange", {"parryRating": 8, "defenseRating": 8}),
    "Glinting": ("orange", {"agility": 8, "hitRating": 8}),
    "Inscribed": ("orange", {"strength": 8, "critRating": 8}),
    "Lucent": ("orange", {"agility": 8, "resilience": 8}),
    "Luminous": ("orange", {"spellPower": 9, "intellect": 8}),
    "Potent": ("orange", {"spellPower": 9, "critRating": 8}),
    "Pristine": ("orange", {"attackPower": 16, "hitRating": 8}),
    "Reckless": ("orange", {"spellPower": 9, "hasteRating": 8}),
    "Resolute": ("orange", {"expertiseRating": 8, "defenseRating": 8}),
    "Resplendent": ("orange", {"strength": 8, "resilience": 8}),
    "Stalwart": ("orange", {"dodgeRating": 8, "defenseRating": 8}),
    "Stark": ("orange", {"attackPower": 16, "hasteRating": 8}),
    "Veiled": ("orange", {"spellPower": 9, "hitRating": 8}),
    "Wicked": ("orange", {"attackPower": 16, "critRating": 8}),
    # green Forest Emerald
    "Timeless": ("green", {"intellect": 8, "stamina": 12}),
    "Jagged": ("green", {"critRating": 8, "stamina": 12}),
    "Vivid": ("green", {"hitRating": 8, "stamina": 12}),
    "Enduring": ("green", {"defenseRating": 8, "stamina": 12}),
    "Steady": ("green", {"resilience": 8, "stamina": 12}),
    "Forceful": ("green", {"hasteRating": 8, "stamina": 12}),
    "Seer's": ("green", {"intellect": 8, "spirit": 8}),
    "Misty": ("green", {"critRating": 8, "spirit": 8}),
    "Shining": ("green", {"hitRating": 8, "spirit": 8}),
    "Turbid": ("green", {"resilience": 8, "spirit": 8}),
    "Intricate": ("green", {"hasteRating": 8, "spirit": 8}),
    "Dazzling": ("green", {"intellect": 8, "mp5": 4}),
    "Sundered": ("green", {"critRating": 8, "mp5": 4}),
    "Lambent": ("green", {"hitRating": 8, "mp5": 4}),
    "Opaque": ("green", {"resilience": 8, "mp5": 4}),
    "Energized": ("green", {"hasteRating": 8, "mp5": 4}),
    "Radiant": ("green", {"critRating": 8, "spellPenetration": 10}),
    "Tense": ("green", {"hitRating": 8, "spellPenetration": 10}),
    "Shattered": ("green", {"hasteRating": 8, "spellPenetration": 10}),
}

cur = None
rares = []
for line in crafting.splitlines():
    m = re.search(r'AtlasLoot_Data\["(Jewel[^"]+)"\]', line)
    if m:
        cur = m.group(1)
        continue
    if not cur or not any(cur.startswith(p) for p in SOCKET):
        continue
    if line.strip() == "}":
        cur = None
        continue
    item = re.search(
        r'\{\s*\d+,\s*"[^"]+",\s*"?(\d+)"?,\s*"=q3=([^"]+)"',
        line,
    )
    if not item:
        continue
    iid, name = int(item.group(1)), item.group(2)
    if not any(marker in name for marker in RARE_MARKERS):
        continue
    prefix = name.split()[0]
    # Defender's / Champion's / Seer's / Guardian's
    for multi in ("Defender's", "Champion's", "Guardian's", "Seer's"):
        if name.startswith(multi):
            prefix = multi
            break
    if prefix not in STAT_BY_PREFIX:
        rares.append((iid, name, None, f"UNKNOWN_PREFIX {prefix}"))
        continue
    color, stats = STAT_BY_PREFIX[prefix]
    rares.append((iid, name, color, stats))

out = Path(__file__).resolve().parents[1] / "tools" / "rare-gem-seeds.lua"
lines = ["\t-- Rare Northrend (maxLevel false) — full AtlasLoot Scarlet/Monarch/Twilight/Forest/Autumn/Sky set"]
for iid, name, color, stats in sorted(rares, key=lambda x: x[0]):
    if color is None:
        lines.append(f"\t-- TODO {iid} {name}: {stats}")
        continue
    parts = ", ".join(f"{k} = {v}" for k, v in stats.items())
    lines.append(
        f"\t[{iid}] = {{ maxLevel = false, color = \"{color}\", stats = {{ {parts} }} }}, -- {name}"
    )
out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"rares={len(rares)} unknown={sum(1 for r in rares if r[2] is None)}")
print(out.read_text(encoding="utf-8")[:2500])

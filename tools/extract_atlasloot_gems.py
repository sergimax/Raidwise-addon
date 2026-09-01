# One-off: extract AtlasLoot Jewel* cut gem item ids from crafting.lua
import re
from pathlib import Path

path = Path(__file__).resolve().parents[1] / "examples" / "AtlasLoot_Crafting" / "crafting.lua"
text = path.read_text(encoding="utf-8", errors="replace")

# Line-oriented: collect q4/q3 gem cuts inside Jewel* tables
current = None
gems = {}  # id -> (quality, name, table)

for line in text.splitlines():
    m = re.search(r'AtlasLoot_Data\["(Jewel[^"]+)"\]', line)
    if m:
        current = m.group(1)
        continue
    if current is None:
        continue
    if line.strip() == "}" or (line.startswith("\tAtlasLoot_Data") and "Jewel" not in line):
        current = None
        continue
    # { N, "sXXXX", "ITEMID", "=qN=Name", ...}
    # { N, "sXXXX", ITEMID, "=qN=Name", ...}
    item = re.search(
        r'\{\s*\d+,\s*"[^"]+",\s*"?(\d+)"?,\s*"=q([1-4])=([^"]+)"',
        line,
    )
    if not item:
        continue
    iid, quality, name = item.group(1), item.group(2), item.group(3)
    # Skip designs / raw stones / bags
    if name.startswith("Design:") or "Dragon's Eye" == name:
        continue
    if "Jewelcrafting" in name or name.endswith(" Setting"):
        continue
    gems[int(iid)] = (int(quality), name, current)

# Group by AtlasLoot table prefix
by_table = {}
for iid, (q, name, table) in sorted(gems.items()):
    by_table.setdefault(table, []).append((iid, q, name))

out = Path(__file__).resolve().parents[1] / "tools" / "atlasloot-gems.txt"
with out.open("w", encoding="utf-8") as f:
    for table in sorted(by_table):
        f.write(f"=== {table} ===\n")
        for iid, q, name in by_table[table]:
            f.write(f"{iid}\tq{q}\t{name}\n")
        f.write("\n")

print(f"wrote {out} ({len(gems)} unique gem items)")
for table in sorted(by_table):
    print(f"  {table}: {len(by_table[table])}")

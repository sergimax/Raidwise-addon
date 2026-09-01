import re
from pathlib import Path

text = Path(
    r"c:\Users\ififo\repos\Raidwise-addon\examples\AtlasLoot_Crafting\crafting.lua"
).read_text(encoding="utf-8", errors="replace")
cur = None
for line in text.splitlines():
    m = re.search(r'AtlasLoot_Data\["(JewelMeta\d+)"\]', line)
    if m:
        cur = m.group(1)
        print("===", cur)
        continue
    if cur:
        if line.strip() == "}":
            cur = None
            continue
        item = re.search(
            r'\{\s*\d+,\s*"[^"]+",\s*"?(\d+)"?,\s*"=q([1-4])=([^"]+)"',
            line,
        )
        if item:
            print(item.group(1), "q" + item.group(2), item.group(3))

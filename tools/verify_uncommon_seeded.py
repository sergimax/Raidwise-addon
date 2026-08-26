import re
from pathlib import Path

cat = Path(r"c:\Users\ififo\repos\Raidwise-addon\Raidwise\GearCheckCatalog.lua").read_text(
    encoding="utf-8"
)
block = re.search(r"local GEMS = \{(.*?)\n\}", cat, re.S).group(1)
ids = [int(x) for x in re.findall(r"\[(\d+)\]", block)]
from collections import Counter

c = Counter(ids)
dups = [i for i, n in c.items() if n > 1]
expected = {
    39900, 39905, 39906, 39907, 39908, 39909, 39910, 39911,
    39912, 39914, 39915, 39916, 39917, 39918,
    39919, 39920, 39927, 39932,
    *range(39933, 39946),
    *range(39946, 39968),
    39968,
    *range(39974, 39987),
    39988, 39989, 39990, 39991, 39992,
}
# 39987 not in atlas list
expected.discard(39987)
present = set(ids) & expected
missing = sorted(expected - set(ids))
dragons = [
    42142, 36766, 42148, 42143, 42152, 42153, 42146, 42158, 42154,
    42150, 42156, 42144, 42149, 36767, 42145, 42155, 42151, 42157,
]
print("gems", len(ids), "unique", len(c), "dups", dups)
print("uncommon expected", len(expected), "present", len(present), "missing", missing)
print("dragons", sum(1 for d in dragons if d in c), "/", len(dragons))
print("39918", c.get(39918), "haste12", "hasteRating = 12" in cat and "[39918]" in cat)

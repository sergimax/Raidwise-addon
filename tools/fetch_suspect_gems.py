import json
import re
import urllib.request
from pathlib import Path

UA = {"User-Agent": "Mozilla/5.0"}

IDS = [
    40115,
    40118,
    40123,
    40151,
    40157,
    40164,
    40170,
    40171,
    40173,
    40175,
    40182,
    41377,
    41379,
    41381,
    41389,
]


def tip(iid: int) -> str:
    url = f"https://nether.wowhead.com/wotlk/tooltip/item/{iid}"
    req = urllib.request.Request(url, headers=UA)
    raw = urllib.request.urlopen(req, timeout=25).read().decode("utf-8", "replace")
    data = json.loads(raw)
    name = data.get("name", "?")
    html = data.get("tooltip", "")
    text = re.sub(r"<[^>]+>", " ", html)
    text = re.sub(r"\s+", " ", text)
    return f"{iid}\t{name}\t{text[:220]}"


lines = []
for iid in IDS:
    try:
        lines.append(tip(iid))
    except Exception as exc:
        lines.append(f"{iid}\tERROR\t{exc}")

out = Path(__file__).resolve().parents[1] / "tools" / "suspect-gem-tips.txt"
out.write_text("\n".join(lines) + "\n", encoding="utf-8")
print("\n".join(lines))

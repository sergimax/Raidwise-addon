import re
from pathlib import Path

import urllib.request

UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

ids = list(range(40111, 40183))
out_lines = []
for iid in ids:
    url = f"https://wotlk.cavernoftime.com/item={iid}"
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        html = urllib.request.urlopen(req, timeout=25).read().decode("utf-8", "replace")
    except Exception as exc:
        # fallback wowhead tooltip API-ish
        try:
            url2 = f"https://nether.wowhead.com/wotlk/tooltip/item/{iid}"
            req2 = urllib.request.Request(url2, headers={"User-Agent": UA})
            raw = urllib.request.urlopen(req2, timeout=25).read().decode("utf-8", "replace")
            out_lines.append(f"{iid}\tWOWHEAD\t{raw[:300].replace(chr(10),' ')}")
        except Exception as exc2:
            out_lines.append(f"{iid}\tERROR\t{exc} | {exc2}")
        continue
    text = re.sub(r"<[^>]+>", " ", html)
    text = re.sub(r"\s+", " ", text)
    m = re.search(
        r"([A-Za-z'\-]+ (?:Cardinal Ruby|Majestic Zircon|King's Amber|Dreadstone|Ametrine|Eye of Zul))"
        r"\s*\+([^I]+?)\s*Item Level",
        text,
    )
    if m:
        out_lines.append(f"{iid}\t{m.group(1).strip()}\t+{m.group(2).strip()}")
    else:
        out_lines.append(f"{iid}\tPARSE\t?")

out = Path(__file__).resolve().parents[1] / "tools" / "epic-gem-stats.txt"
out.write_text("\n".join(out_lines) + "\n", encoding="utf-8")
print("\n".join(out_lines[:30]))
print("...")
print("\n".join(out_lines[-10:]))
print(f"wrote {out} lines={len(out_lines)}")

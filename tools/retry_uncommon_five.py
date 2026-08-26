import re
import urllib.request

UA = {"User-Agent": "Mozilla/5.0"}
IDS = {
    39912: "Brilliant Sun Crystal",
    39946: "Luminous Huge Citrine",
    39968: "Timeless Dark Jade",
    39979: "Seer's Dark Jade",
    39984: "Dazzling Dark Jade",
}

for iid, expect in IDS.items():
    ok = False
    for host, url in [
        ("cot", f"https://wotlk.cavernoftime.com/item={iid}"),
        ("wh", f"https://www.wowhead.com/wotlk/item={iid}"),
        ("cdb", f"https://wowclassicdb.com/wotlk/item/{iid}"),
    ]:
        try:
            req = urllib.request.Request(url, headers=UA)
            html = urllib.request.urlopen(req, timeout=25).read().decode("utf-8", "replace")
            text = re.sub(r"<[^>]+>", " ", html)
            text = re.sub(r"\s+", " ", text)
            m = re.search(
                r"\+(\d+)\s+[A-Za-z ]+(?:Rating|Power|Spirit|Stamina|Intellect|Agility|Strength|Penetration|seconds)",
                text,
            )
            # Prefer gem-name vicinity
            m2 = re.search(
                re.escape(expect.split()[0]) + r".{0,40}\+(.{0,80}?)(?:Item Level|Requires|\"Matches)",
                text,
                re.I,
            )
            snippet = m2.group(0) if m2 else (m.group(0) if m else "")
            if "+" in snippet or m:
                print(f"{iid}\t{host}\tOK\t{snippet[:140]}")
                ok = True
                break
            print(f"{iid}\t{host}\tNO\tlen={len(html)}")
        except Exception as exc:
            print(f"{iid}\t{host}\tERR\t{exc}")
    if not ok:
        print(f"{iid}\tALL_FAILED\t{expect}")

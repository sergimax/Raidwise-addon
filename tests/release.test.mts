import assert from "node:assert/strict";
import test from "node:test";
import { getReleaseNotes } from "../scripts/prepare-release.mts";
import { getPackageFiles, packageAddon } from "../scripts/package-addon.mts";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const toc = "## Version: 3.2.1\r\n";
const lua = 'Addon.version = "3.2.1"\n';
const changelog = "# Changelog\r\n\r\n## [3.2.1] - 2026-10-31\r\n\r\n### Fixed\r\n- Corrected a bug.\r\n\r\n## [3.2.0] - 2026-10-30\r\n\r\n### Added\r\n- Older change.\r\n";

test("runtime package includes only TOC modules and media and rejects missing dependencies", () => {
  const tracked = ["Raidwise/Raidwise.toc", "Raidwise/Core.lua", "Raidwise/Retired.lua", "Raidwise/Icons/Mark.tga"];
  assert.deepEqual(getPackageFiles("## Title: Example\r\nCore.lua\r\n", tracked),
    ["Raidwise/Core.lua", "Raidwise/Icons/Mark.tga", "Raidwise/Raidwise.toc"]);
  assert.throws(() => getPackageFiles("Missing.lua", tracked), /Missing tracked/);
  for (const path of ["../Outside.lua", "/Outside.lua", "Layout.xml"]) {
    assert.throws(() => getPackageFiles(path, tracked), /Unsupported/);
  }
});

test("installable ZIP contains every allowlisted tracked runtime file and no retired modules", () => {
  const dir = mkdtempSync(join(tmpdir(), "raidwise-package-"));
  try {
    const output = join(dir, "addon.zip");
    const expected = packageAddon(output);
    const zip = readFileSync(output);
    const end = zip.lastIndexOf(Buffer.from([0x50, 0x4b, 0x05, 0x06]));
    assert(end >= 0);
    let offset = zip.readUInt32LE(end + 16);
    const names: string[] = [];
    for (let i = 0; i < zip.readUInt16LE(end + 10); i++) {
      assert.equal(zip.readUInt32LE(offset), 0x02014b50);
      const nameLength = zip.readUInt16LE(offset + 28);
      const name = zip.subarray(offset + 46, offset + 46 + nameLength).toString();
      if (!name.endsWith("/")) names.push(name);
      offset += 46 + nameLength + zip.readUInt16LE(offset + 30) + zip.readUInt16LE(offset + 32);
    }
    assert.deepEqual(names.sort(), expected);
    assert(!names.includes("Raidwise/PlayerHistory.lua"));
  } finally { rmSync(dir, {recursive:true, force:true}); }
});

test("release notes include only the requested version and accept CRLF", () => {
  assert.equal(getReleaseNotes("v3.2.1", toc, lua, changelog), "### Fixed\n- Corrected a bug.\n");
});

test("release rejects malformed tags, mismatched versions and missing notes", () => {
  for (const tag of ["3.2.1", "v03.2.1", "v3.2.1-beta", "v3.2.1/other"]) {
    assert.throws(() => getReleaseNotes(tag, toc, lua, changelog), /Release tags/);
  }
  assert.throws(() => getReleaseNotes("v3.2.2", toc, lua, changelog), /must match/);
  assert.throws(() => getReleaseNotes("v3.2.1", "", lua, changelog), /must match/);
  assert.throws(() => getReleaseNotes("v3.2.1", toc, 'Addon.version = "3.2.0"', changelog), /must match/);
  assert.throws(() => getReleaseNotes("v3.2.1", toc, lua, ""), /Missing dated/);
  assert.throws(() => getReleaseNotes("v3.2.1", toc, lua, "## [3.2.1] - 2026-10-31\n\n### Fixed\n"), /no release notes/);
});

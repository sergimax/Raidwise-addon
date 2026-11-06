import assert from "node:assert/strict";
import test from "node:test";
import { getReleaseNotes } from "../scripts/prepare-release.mts";

const toc = "## Version: 3.2.1\r\n";
const lua = 'Addon.version = "3.2.1"\n';
const changelog = "# Changelog\r\n\r\n## [3.2.1] - 2026-10-31\r\n\r\n### Fixed\r\n- Corrected a bug.\r\n\r\n## [3.2.0] - 2026-10-30\r\n\r\n### Added\r\n- Older change.\r\n";

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

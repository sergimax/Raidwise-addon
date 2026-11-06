import { readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

export function getReleaseNotes(tag: string, toc: string, lua: string, changelog: string): string {
  if (!/^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/.test(tag)) {
    throw new Error("Release tags must use vMAJOR.MINOR.PATCH (stable versions only).");
  }
  const version = tag.slice(1);
  const tocVersion = toc.match(/^## Version:\s*(\S+)\s*$/m)?.[1];
  const luaVersion = lua.match(/^Addon\.version\s*=\s*"([^"]+)"/m)?.[1];
  if (tocVersion !== version || luaVersion !== version) {
    throw new Error(`Tag ${tag} must match Raidwise.toc and Addon.version.`);
  }
  const sections = changelog.replace(/\r\n/g, "\n").split(/^## /m);
  const section = sections.find((entry) => entry.startsWith(`[${version}] - `));
  if (!section || !/^\[\d+\.\d+\.\d+\] - \d{4}-\d{2}-\d{2}\n/.test(section)) {
    throw new Error(`Missing dated CHANGELOG.md entry for ${version}.`);
  }
  const notes = section.slice(section.indexOf("\n") + 1).trim();
  if (!/^\s*-\s+\S/m.test(notes)) {
    throw new Error(`CHANGELOG.md entry for ${version} has no release notes.`);
  }
  return `${notes}\n`;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const [tag, notesPath] = process.argv.slice(2);
  if (!tag || !notesPath) throw new Error("Usage: node scripts/prepare-release.mts <tag> <notes-path>");
  writeFileSync(notesPath, getReleaseNotes(tag,
    readFileSync("Raidwise/Raidwise.toc", "utf8"),
    readFileSync("Raidwise/Raidwise.lua", "utf8"),
    readFileSync("CHANGELOG.md", "utf8")));
}

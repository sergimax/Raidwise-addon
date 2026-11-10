import { execFileSync } from "node:child_process";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";

/** Runtime allowlist: executable TOC entries plus tracked media, never spare Lua files. */
export function getPackageFiles(toc: string, tracked: string[], addon = "Raidwise"): string[] {
  const files = new Set([`${addon}/${addon}.toc`]);
  for (const raw of toc.split(/\r?\n/)) {
    const entry = raw.trim().replaceAll("\\", "/");
    if (!entry || entry.startsWith("#")) continue;
    // XML would need recursive includes; fail closed until that format is supported.
    if (!/^[A-Za-z0-9_/-]+\.lua$/.test(entry) || entry.startsWith("/")) {
      throw new Error(`Unsupported TOC entry: ${entry}`);
    }
    files.add(`${addon}/${entry}`);
  }
  for (const file of tracked) {
    if (new RegExp(`^${addon}/[A-Za-z0-9_ /.-]+\\.(blp|tga|png|jpg|ogg|mp3|wav|ttf)$`, "i").test(file)) files.add(file);
  }
  for (const file of files) {
    if (!tracked.includes(file)) throw new Error(`Missing tracked runtime file: ${file}`);
  }
  return [...files].sort();
}

export function packageAddon(output: string): string[] {
  const files: string[] = [];
  for (const addon of ["Raidwise", "Raidwise_EPGP"]) {
    const toc = execFileSync("git", ["show", `HEAD:${addon}/${addon}.toc`], { encoding: "utf8" });
    const tracked = execFileSync("git", ["ls-tree", "-r", "--name-only", "HEAD", "--", `${addon}/`], { encoding: "utf8" }).trim().split("\n");
    files.push(...getPackageFiles(toc, tracked, addon));
  }
  execFileSync("git", ["archive", "--format=zip", `--output=${resolve(output)}`, "HEAD", "--", ...files]);
  return files;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  if (process.argv.length !== 3) throw new Error("Usage: node scripts/package-addon.mts <output.zip>");
  console.log(`Packaged ${packageAddon(process.argv[2]).length} runtime files from HEAD`);
}

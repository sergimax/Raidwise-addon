const { spawnSync } = require("node:child_process");
const { mkdirSync, writeFileSync } = require("node:fs");
const { resolve } = require("node:path");

const root = resolve(__dirname, "..");
const lines = ["Raidwise CLI diagnostics v1", `Time: ${new Date().toISOString()}`, `Node: ${process.version}`, `Platform: ${process.platform} ${process.arch}`];
const revision = spawnSync("git", ["rev-parse", "HEAD"], { cwd: root, encoding: "utf8" });
lines.push(`Commit: ${revision.stdout?.trim() || "unknown"}`);
const status = spawnSync("git", ["status", "--porcelain"], { cwd: root, encoding: "utf8" });
lines.push(`Worktree: ${status.status === 0 ? (status.stdout.trim() ? "modified" : "clean") : "unknown"}`);
console.log("Running type checks and all offline regressions (including circular UI anchors)...");
const result = spawnSync(process.execPath, [process.env.npm_execpath, "run", "check"], {
  cwd: root, encoding: "utf8", maxBuffer: 16 * 1024 * 1024, env: { ...process.env, FORCE_COLOR: "0" },
});
lines.push(result.stdout || "", result.stderr || "");
if (result.error) lines.push(String(result.error));
lines.push(`Result: ${result.status === 0 ? "PASS" : "FAIL"}`);
lines.push("Scope: offline Lua 5.1 tests with WoW mocks; run /rw diagnose in game too.");
const report = lines.join("\n");
const directory = resolve(root, "diagnostics");
mkdirSync(directory, { recursive: true });
const path = resolve(directory, "latest.txt");
writeFileSync(path, report, "utf8");
console.log(report);
console.log(`Report saved to ${path}`);
process.exitCode = result.status === 0 ? 0 : 1;

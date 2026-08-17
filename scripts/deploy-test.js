const fs = require("fs");
const path = require("path");

const destArg = process.argv[2];
if (!destArg) {
  console.error("Usage: node scripts/deploy-test.js <destination>");
  process.exit(1);
}

const repoRoot = path.resolve(__dirname, "..");
const srcDir = path.join(repoRoot, "Raidwise");
const tocPath = path.join(srcDir, "Raidwise.toc");
const destInput = path.resolve(destArg);
const destDir =
  path.basename(destInput).toLowerCase() === "raidwise"
    ? destInput
    : path.join(destInput, "Raidwise");

if (!fs.existsSync(srcDir)) {
  console.error("Source directory not found: " + srcDir);
  process.exit(1);
}

const now = new Date();
const hours = String(now.getHours()).padStart(2, "0");
const minutes = String(now.getMinutes()).padStart(2, "0");
const titleLine = "## Title: Raidwise TEST " + hours + minutes;

const toc = fs.readFileSync(tocPath, "utf8");
if (!/^## Title:.*$/m.test(toc)) {
  console.error("Could not find ## Title line in " + tocPath);
  process.exit(1);
}
fs.writeFileSync(tocPath, toc.replace(/^## Title:.*$/m, titleLine), "utf8");
console.log("Updated title: " + titleLine);

fs.mkdirSync(path.dirname(destDir), { recursive: true });
fs.cpSync(srcDir, destDir, { recursive: true, force: true });

function listFiles(dir, base) {
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push.apply(files, listFiles(fullPath, base));
    } else {
      files.push(path.relative(base, fullPath));
    }
  }
  return files;
}

const files = listFiles(destDir, destDir);
console.log("Copied " + files.length + " file(s) to " + destDir);
for (let i = 0; i < files.length; i++) {
  console.log("  " + files[i]);
}

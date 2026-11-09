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
const useColor = process.stdout.isTTY && process.env.NO_COLOR === undefined;
const colors = {
  reset: "\u001b[0m",
  green: "\u001b[32m",
  yellow: "\u001b[33m",
  cyan: "\u001b[36m",
  dim: "\u001b[2m",
};

function color(text, name) {
  return useColor ? colors[name] + text + colors.reset : text;
}

if (!fs.existsSync(srcDir)) {
  console.error("Source directory not found: " + srcDir);
  process.exit(1);
}

const now = new Date();
const hours = String(now.getHours()).padStart(2, "0");
const minutes = String(now.getMinutes()).padStart(2, "0");
const titleLine = "## Title: Raidwise TEST " + hours + minutes;

// const toc = fs.readFileSync(tocPath, "utf8");
// if (!/^## Title:.*$/m.test(toc)) {
//   console.error("Could not find ## Title line in " + tocPath);
//   process.exit(1);
// }
// fs.writeFileSync(tocPath, toc.replace(/^## Title:.*$/m, titleLine), "utf8");
// console.log("Updated title: " + titleLine);

fs.mkdirSync(path.dirname(destDir), { recursive: true });

function listChangedFiles(dir, base) {
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push.apply(files, listChangedFiles(fullPath, base));
    } else {
      const relativePath = path.relative(base, fullPath);
      const destPath = path.join(destDir, relativePath);
      let status = "new";
      if (fs.existsSync(destPath) && fs.statSync(destPath).isFile()) {
        if (fs.readFileSync(fullPath).equals(fs.readFileSync(destPath))) continue;
        status = "updated";
      }
      files.push({ path: relativePath, status });
    }
  }
  return files;
}

const files = listChangedFiles(srcDir, srcDir);
fs.cpSync(srcDir, destDir, { recursive: true, force: true });

const addedCount = files.filter((file) => file.status === "new").length;
const updatedCount = files.length - addedCount;
console.log(color("Raidwise test deployment", "cyan"));
console.log("Destination: " + destDir);
console.log(
  "Copied " + files.length + " file(s): " +
    color(addedCount + " new", "green") + ", " +
    color(updatedCount + " updated", "yellow")
);

if (files.length === 0) {
  console.log(color("No changes; destination is already up to date.", "dim"));
} else {
  for (const file of files) {
    const label = file.status === "new" ? "NEW " : "UPDATED ";
    const labelColor = file.status === "new" ? "green" : "yellow";
    console.log("  " + color(label.padEnd(7), labelColor) + file.path);
  }
}

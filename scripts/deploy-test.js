const fs = require("fs");
const path = require("path");

const destArg = process.argv[2];
if (!destArg) {
  console.error("Usage: node scripts/deploy-test.js <destination>");
  process.exit(1);
}

const repoRoot = path.resolve(__dirname, "..");
const destInput = path.resolve(destArg);
const destRoot = ["raidwise", "raidwise_epgp"].includes(path.basename(destInput).toLowerCase())
  ? path.dirname(destInput)
  : destInput;
const addons = ["Raidwise", "Raidwise_EPGP"];
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

for (const addon of addons) {
  if (!fs.existsSync(path.join(repoRoot, addon))) {
    console.error("Source directory not found: " + path.join(repoRoot, addon));
    process.exit(1);
  }
}

fs.mkdirSync(destRoot, { recursive: true });

function listChangedFiles(dir, base, destDir, prefix) {
  const files = [];
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push.apply(files, listChangedFiles(fullPath, base, destDir, prefix));
    } else {
      const relativePath = path.relative(base, fullPath);
      const destPath = path.join(destDir, relativePath);
      let status = "new";
      if (fs.existsSync(destPath) && fs.statSync(destPath).isFile()) {
        if (fs.readFileSync(fullPath).equals(fs.readFileSync(destPath))) continue;
        status = "updated";
      }
      files.push({ path: path.join(prefix, relativePath), sourcePath: fullPath, destPath, status });
    }
  }
  return files;
}

const files = [];
for (const addon of addons) {
  const srcDir = path.join(repoRoot, addon);
  const destDir = path.join(destRoot, addon);
  files.push.apply(files, listChangedFiles(srcDir, srcDir, destDir, addon));
  fs.cpSync(srcDir, destDir, { recursive: true, force: true });
}

const addedCount = files.filter((file) => file.status === "new").length;
const updatedCount = files.length - addedCount;
console.log(color("Raidwise test deployment", "cyan"));
console.log("Destination: " + destRoot);
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

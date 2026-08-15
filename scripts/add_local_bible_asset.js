#!/usr/bin/env node
// Usage:
// node scripts/add_local_bible_asset.js --src path/to/youversion_1260.json --version NASV

const fs = require('fs');
const path = require('path');

function arg(name) {
  const i = process.argv.indexOf(name);
  if (i === -1) return null;
  return process.argv[i+1];
}

const src = arg('--src') || arg('-s');
const versionId = (arg('--version') || arg('-v') || '').toUpperCase();
if (!src || !versionId) {
  console.error('Usage: --src <file> --version <VERSION_ID>');
  process.exit(2);
}

const repoRoot = path.resolve(__dirname, '..');
const outDir = path.join(repoRoot, 'assets', 'bible');
if (!fs.existsSync(src)) {
  console.error('Source file not found:', src);
  process.exit(3);
}
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

const filename = `youversion_${Date.now()}_${path.basename(src)}`.replace(/[^a-zA-Z0-9._-]/g, '_');
const dest = path.join(outDir, filename);
fs.copyFileSync(src, dest);
console.log('Copied to', dest);

// update catalog
const catalogPath = path.join(repoRoot, 'assets', 'catalog', 'bible_catalog.json');
const catalogRaw = fs.readFileSync(catalogPath, 'utf8');
const catalog = JSON.parse(catalogRaw);
let found = false;
for (const pkg of catalog.packages) {
  if ((pkg.versionId || '').toString().toUpperCase() === versionId) {
    pkg.install = { type: 'asset', path: `assets/bible/${filename}` };
    pkg.approved = true;
    try {
      const stats = fs.statSync(dest);
      pkg.fileSizeBytes = stats.size;
      pkg.offlineSizeBytes = stats.size;
    } catch (_) {}
    found = true;
    break;
  }
}
if (!found) {
  // add new entry
  catalog.packages.push({
    id: versionId.toLowerCase(),
    versionId: versionId,
    name: versionId,
    abbreviation: versionId,
    language: 'und',
    languageName: 'Unknown',
    description: `Imported local asset ${filename}`,
    license: '',
    attribution: '',
    source: '',
    commercialUse: false,
    redistribution: false,
    approved: true,
    category: ['bundled'],
    fileSizeBytes: 0,
    offlineSizeBytes: 0,
    updatedAt: new Date().toISOString().split('T')[0],
    install: { type: 'asset', path: `assets/bible/${filename}` },
  });
}
fs.writeFileSync(catalogPath, JSON.stringify(catalog, null, 2), 'utf8');
console.log('Updated catalog at', catalogPath);

// update pubspec.yaml assets list
const pubspecPath = path.join(repoRoot, 'pubspec.yaml');
const pubRaw = fs.readFileSync(pubspecPath, 'utf8');
const lines = pubRaw.split(/\r?\n/);
let assetsIndex = lines.findIndex(l => l.trim() === 'assets:' || l.trim().startsWith('assets:'));
if (assetsIndex === -1) {
  console.error('Could not find assets section in pubspec.yaml; please add the file manually:', `assets/bible/${filename}`);
  process.exit(0);
}
// find last asset entry indentation (lines starting with 4 spaces and '-') after assetsIndex
let insertAt = assetsIndex + 1;
for (let i = assetsIndex + 1; i < lines.length; i++) {
  const line = lines[i];
  if (/^\s{4}-\s/.test(line)) insertAt = i + 1; else break;
}
const assetLine = `    - assets/bible/${filename}`;
if (!lines.some(l => l.trim() === `- assets/bible/${filename}`)) {
  lines.splice(insertAt, 0, assetLine);
  fs.writeFileSync(pubspecPath, lines.join('\n'), 'utf8');
  console.log('Updated pubspec.yaml to include asset. Run `flutter pub get` and rebuild.');
} else {
  console.log('pubspec.yaml already contains the asset.');
}

console.log('Done. Now run:\n  flutter pub get\n  flutter run -d <device>');

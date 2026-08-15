#!/usr/bin/env node
// Wrapper: fetch a YouVersion/Bible Brain bible and add it to the repo catalog
// Usage:
//   node scripts/fetch_and_add_bible.js --bible 4125 --version ORM [--all]

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function arg(name) {
  const i = process.argv.indexOf(name);
  if (i === -1) return null;
  return process.argv[i+1];
}

const bibleId = arg('--bible') || arg('-b');
const versionId = (arg('--version') || arg('-v') || '').toUpperCase();
const all = !!arg('--all');
const book = (arg('--book') || arg('-k')) || null;

if (!bibleId || !versionId) {
  console.error('Usage: --bible <ID> --version <VERSION_ID> [--all]');
  process.exit(2);
}

const repoRoot = path.resolve(__dirname, '..');

try {
  const fetchArgs = [`node`, `scripts/fetch_youversion_bible.js`, `--bible`, bibleId];
  if (all) fetchArgs.push('--all');
  if (book) {
    fetchArgs.push('--book', book);
  }
  console.log('Running fetch script...');
  const out = execSync(fetchArgs.join(' '), { cwd: repoRoot, stdio: 'pipe' }).toString();
  console.log(out);
  // look for saved path
  const m = out.match(/Saved bible asset to (.+)$/m);
  if (!m) {
    console.error('Fetch did not produce an asset path. Check debug output above.');
    process.exit(3);
  }
  const saved = m[1].trim();
  if (!fs.existsSync(saved)) {
    console.error('Saved file not found:', saved);
    process.exit(4);
  }

  console.log('Adding local bible asset to catalog...');
  const addCmd = `node scripts/add_local_bible_asset.js --src "${saved}" --version ${versionId}`;
  const addOut = execSync(addCmd, { cwd: repoRoot, stdio: 'pipe' }).toString();
  console.log(addOut);
  console.log('Done. Run `flutter pub get` and rebuild to include the asset.');
} catch (err) {
  console.error('Error during fetch/add:', err && err.message ? err.message : err);
  process.exit(1);
}

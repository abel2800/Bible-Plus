#!/usr/bin/env node
// Generate a candidate catalog JSON from YouVersion / Bible Brain metadata.
// Usage: set env YVP_KEY then run:
// node scripts/generate_youversion_catalog.js --languages am,om,en --limit 50 --out tmp/youversion_catalog.json

const https = require('https');
const fs = require('fs');
const path = require('path');

function usage() {
  console.log('Usage: YVP_KEY=... node scripts/generate_youversion_catalog.js --languages am,om,en --limit 50 --out path.json');
  process.exit(1);
}

const rawArgs = process.argv.slice(2);
const argv = {};
for (let i = 0; i < rawArgs.length; i++) {
  const a = rawArgs[i];
  if (!a) continue;
  if (a.startsWith('--')) {
    const key = a.replace(/^--/, '');
    const next = rawArgs[i + 1];
    if (next && !next.startsWith('--')) { argv[key] = next; i++; } else { argv[key] = true; }
  }
}

const KEY = process.env.YVP_KEY || process.env.YVP_API_KEY || process.env.BIBLE_BRAIN_API_KEY;
if (!KEY) {
  console.error('Missing API key. Set YVP_KEY or YVP_API_KEY in environment.');
  usage();
}

const languages = (argv.languages || 'am,om,en').split(',').map(s => s.trim()).filter(Boolean);
const limit = parseInt(argv.limit || '50', 10) || 50;
const out = argv.out || 'tmp/youversion_catalog.json';

function httpGetJson(url, headers) {
  return new Promise((resolve, reject) => {
    const opts = new URL(url);
    opts.headers = headers || {};
    https.get(opts, res => {
      const { statusCode } = res;
      let raw = '';
      res.setEncoding('utf8');
      res.on('data', (c) => raw += c);
      res.on('end', () => {
        if (statusCode >= 200 && statusCode < 300) {
          try { resolve(JSON.parse(raw)); } catch (e) { reject(e); }
        } else {
          reject(new Error('HTTP ' + statusCode + ' ' + raw.slice(0,200)));
        }
      });
    }).on('error', reject);
  });
}

async function listBiblesForLanguage(lang) {
  const url = `https://api.youversion.com/v1/bibles?language_ranges%5B%5D=${encodeURIComponent(lang)}&limit=${limit}`;
  const headers = { 'X-YVP-App-Key': KEY };
  for (let attempt = 1; attempt <= 4; attempt++) {
    try {
      const json = await httpGetJson(url, headers);
      return json && json.data ? json.data : [];
    } catch (error) {
      if (attempt === 4) throw error;
      const wait = attempt * 1500;
      console.error(`Retrying ${lang} in ${wait}ms: ${error.message || error}`);
      await new Promise((resolve) => setTimeout(resolve, wait));
    }
  }
  return [];
}

(async () => {
  const outDir = path.dirname(out);
  if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
  const results = [];
  for (const lang of languages) {
    console.log('Listing bibles for', lang);
    try {
      const bibles = await listBiblesForLanguage(lang);
      for (const b of bibles) {
        results.push({ id: b.id, abbreviation: b.abbreviation, name: b.name, languageIso: b.language_iso, hasText: !!b.has_text, hasAudio: !!b.has_audio, copyright: b.copyright || null });
      }
    } catch (e) {
      console.error('Failed to list for', lang, e.message || e);
    }
  }
  fs.writeFileSync(out, JSON.stringify({ generatedAt: new Date().toISOString(), results }, null, 2), 'utf8');
  console.log('Wrote', out, 'entries:', results.length);
})();

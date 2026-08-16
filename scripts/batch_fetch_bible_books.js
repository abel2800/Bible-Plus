#!/usr/bin/env node
// Batch-fetch each book for a bible id by invoking fetch_youversion_bible.js per-book
// This reduces rate-limit pressure by spacing requests.
// Usage:
// YVP_KEY=... node scripts/batch_fetch_bible_books.js --bible 1260 --version NASV --delay 8000

const { spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function usage() { console.log('Usage: node scripts/batch_fetch_bible_books.js --bible 1260 --version NASV [--delay ms] [--books COMMA_SEP]'); process.exit(1); }
const rawArgs = process.argv.slice(2);
const argv = {};
for (let i = 0; i < rawArgs.length; i++) {
  const a = rawArgs[i]; if (!a) continue;
  if (a.startsWith('--')) { const key = a.replace(/^--/, ''); const next = rawArgs[i+1]; if (next && !next.startsWith('--')) { argv[key]=next; i++; } else argv[key]=true; }
}
if (!argv.bible) usage();
const bible = argv.bible;
const version = argv.version || bible;
const delayMs = parseInt(argv.delay || '8000', 10) || 8000;
const booksList = argv.books ? argv.books.split(',').map(s=>s.trim()).filter(Boolean) : null;

// read debug file if available to enumerate books, else attempt to call list via fetch script's debug outputs
const debugDir = path.join('scripts','debug');
let bookIds = [];
if (booksList && booksList.length) {
  bookIds = booksList;
} else if (fs.existsSync(path.join(debugDir, `https___api_youversion_com_v1_bibles_${bible}_books.json`))) {
  const raw = fs.readFileSync(path.join(debugDir, `https___api_youversion_com_v1_bibles_${bible}_books.json`),'utf8');
  try {
    const j = JSON.parse(raw);
    const data = j.data || j.books || [];
    bookIds = data.map(b=>b.id || b.book_id || b.abbreviation || b.abbr || b.number).filter(Boolean);
  } catch(e) { bookIds = [] }
}

if (!bookIds.length) {
  console.log('No book list found in debug; defaulting to simple set of book abbreviations (GEN,EXO,LEV...)');
  bookIds = ['GEN','EXO','LEV','NUM','DEU','JOS','JDG','RUT','1SA','2SA','1KI','2KI','1CH','2CH','EZR','NEH','EST','JOB','PSA','PRO','ECC','SNG','ISA','JER','LAM','EZK','DAN','HOS','JOH','AMO','OBA','JON','MIC','NAM','HAB','ZEP','HAG','ZEC','MAL','MAT','MRK','LUK','JHN','ACT','ROM','1CO','2CO','GAL','EPH','PHP','COL','1TH','2TH','1TI','2TI','TIT','PHM','HEB','JAS','1PE','2PE','1JN','2JN','3JN','JUD','REV'];
}

console.log('Will fetch', bookIds.length, 'books for bible', bible, 'with delay', delayMs, 'ms');
for (let i = 0; i < bookIds.length; i++) {
  const b = bookIds[i];
  console.log(`Fetching book ${b} (${i+1}/${bookIds.length})`);
  const res = spawnSync('node', ['scripts/fetch_youversion_bible.js','--bible',bible,'--book',b,'--version',version], { stdio: 'inherit', env: process.env });
  if (res.error) {
    console.error('Error running fetch script for', b, res.error);
  }
  if (i < bookIds.length - 1) {
    console.log('Sleeping', delayMs, 'ms before next book');
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)),0,0,delayMs);
  }
}

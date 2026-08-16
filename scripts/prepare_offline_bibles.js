#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

function usage() {
  console.log('Usage: node prepare_offline_bibles.js --input <input.json> --out <outdir> [--id ID] [--name NAME] [--lang LANG]');
  process.exit(1);
}

// simple arg parsing to avoid external deps
const rawArgs = process.argv.slice(2);
const argv = {};
for (let i = 0; i < rawArgs.length; i++) {
  const a = rawArgs[i];
  if (!a) continue;
  if (a === '--help' || a === '-h') usage();
  if (a.startsWith('--')) {
    const key = a.replace(/^--/, '');
    const next = rawArgs[i + 1];
    if (next && !next.startsWith('--')) {
      argv[key] = next;
      i++;
    } else {
      argv[key] = true;
    }
  }
}
if (!argv.input || !argv.out) usage();

const input = argv.input;
const outDir = argv.out;
const id = argv.id || path.basename(input).replace(/\.[^.]+$/, '');
const name = argv.name || id;
const lang = argv.lang || 'und';

if (!fs.existsSync(input)) {
  console.error('Input file not found:', input);
  process.exit(2);
}

function normalize(decoded) {
  // If decoded already has books, return as-is (but ensure basic translation metadata)
  if (decoded && typeof decoded === 'object' && Array.isArray(decoded.books)) {
    const out = {
      schemaVersion: decoded.schemaVersion || 1,
      translation: Object.assign({ id, name, language: lang, license: 'See source' }, decoded.translation || {}),
      books: decoded.books.map(b => {
        const book = { id: b.id || b.bookId || b.book || b.number || 0, name: b.name || b.bookName || b.title || '', testament: b.testament || (b.id <= 39 ? 'OT' : 'NT') };
        // normalize chapters -> ensure chapters is array of { number, verses:[{verse,text}] }
        const chapters = (b.chapters || b.verses || []).map((c, idx) => {
          if (Array.isArray(c)) {
            return { number: idx + 1, verses: c.map((v, vi) => ({ verse: (v.verse || vi + 1), text: (v.text || v.verse_text || v.content || v || '').toString() })) };
          }
          if (c && typeof c === 'object') {
            const versesRaw = c.verses || Object.values(c).find(v => Array.isArray(v)) || [];
            return { number: c.number || c.chapter || idx + 1, verses: (versesRaw || []).map((v, vi) => ({ verse: (v.verse || vi + 1), text: (v.text || v.verse_text || v.content || v || '').toString() })) };
          }
          return { number: idx + 1, verses: [] };
        });
        book.chapters = chapters.filter(ch => (ch.verses || []).length > 0);
        return book;
      }).filter(b => (b.chapters || []).length > 0),
    };
    return out;
  }

  // If decoded is a flat list of rows {book, chapter, verse, text}
  if (Array.isArray(decoded)) {
    const byBook = {};
    decoded.forEach(row => {
      const bookId = Number(row.book || row.book_id || row.bookId || row.bookNum || 0);
      if (!bookId) return;
      const chapter = Number(row.chapter || row.chap || 0) || 1;
      const verse = Number(row.verse || row.verse_num || 0) || 1;
      const text = (row.text || row.verse_text || row.content || '').toString();
      if (!text) return;
      byBook[bookId] = byBook[bookId] || { id: bookId, name: row.book_name || row.bookName || '', testament: bookId <= 39 ? 'OT' : 'NT', chapters: [] };
      const book = byBook[bookId];
      let chap = book.chapters.find(c => c.number === chapter);
      if (!chap) { chap = { number: chapter, verses: [] }; book.chapters.push(chap); }
      chap.verses.push({ verse, text });
    });
    const books = Object.keys(byBook).map(k => byBook[k]).sort((a,b)=>a.id-b.id);
    return { schemaVersion: 1, translation: { id, name, language: lang, license: 'See source' }, books };
  }

  throw new Error('Unsupported input format');
}

const raw = fs.readFileSync(input, 'utf8');
let decoded;
try { decoded = JSON.parse(raw); } catch (e) { console.error('Input is not valid JSON'); process.exit(3); }

const normalized = normalize(decoded);
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
const outPath = path.join(outDir, `${id}.json`);
fs.writeFileSync(outPath, JSON.stringify(normalized));
console.log('Wrote', outPath, 'size bytes:', fs.statSync(outPath).size);

// Optionally produce per-book minimal files (one file per book) to support delta downloads
const perBookDir = path.join(outDir, `${id}-books`);
if (!fs.existsSync(perBookDir)) fs.mkdirSync(perBookDir, { recursive: true });
for (const b of normalized.books) {
  const bookPath = path.join(perBookDir, `${id}-book-${b.id}.json`);
  fs.writeFileSync(bookPath, JSON.stringify({ schemaVersion: 1, translation: normalized.translation, book: b }));
}
console.log('Wrote per-book files to', perBookDir);

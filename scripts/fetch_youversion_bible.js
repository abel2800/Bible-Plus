#!/usr/bin/env node
// Fetch Bible book(s) from YouVersion Platform API and save as assets/bible/{version}.json
// Usage (PowerShell):
// $env:YVP_KEY="YOUR_KEY"; node scripts/fetch_youversion_bible.js --bible 1260 --book Genesis
// Or to fetch whole bible: node scripts/fetch_youversion_bible.js --bible 1260 --all

const fs = require('fs');
const path = require('path');

const KEY = process.env.YVP_KEY || process.env.YVP_API_KEY || process.env.BIBLE_BRAIN_API_KEY;
const KEY_SOURCE = process.env.YVP_KEY ? 'YVP_KEY' : process.env.YVP_API_KEY ? 'YVP_API_KEY' : process.env.BIBLE_BRAIN_API_KEY ? 'BIBLE_BRAIN_API_KEY' : null;
if (!KEY) {
  console.error('Missing API key. Set YVP_KEY, YVP_API_KEY or BIBLE_BRAIN_API_KEY in your environment.');
  process.exit(1);
} else {
  console.error(`Using API key from env var: ${KEY_SOURCE}`);
}

const args = process.argv.slice(2);
function arg(name) {
  const i = args.indexOf(name);
  if (i === -1) return null;
  return args[i+1] || null;
}

const BIBLE_ID = arg('--bible') || arg('-b');
const BOOK_QUERY = arg('--book') || arg('-k');
const FETCH_ALL = args.includes('--all');
const OUT_DIR = path.join(__dirname, '..', 'assets', 'bible');

if (!BIBLE_ID) {
  console.error('Missing --bible <BIBLE_ID> (YouVersion Bible ID).');
  process.exit(1);
}

const API_BASE = 'https://api.youversion.com/v1';

const { URL } = require('url');
const http = require('http');
const https = require('https');

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

function httpGetText(url, attempt = 1, maxAttempts = 6) {
  return new Promise((resolve, reject) => {
    try {
      const u = new URL(url);
      const lib = u.protocol === 'https:' ? https : http;
      const options = {
        method: 'GET',
        headers: { 'X-YVP-App-Key': KEY, 'Accept': 'application/json' }
      };
      const req = lib.request(u, options, async (res) => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', chunk => data += chunk);
        res.on('end', async () => {
          if (res.statusCode >= 200 && res.statusCode < 300) {
            // small delay to avoid bursts
            await sleep(250);
            return resolve(data);
          }
          // handle rate limiting with retry/backoff
          if (res.statusCode === 429 && attempt < maxAttempts) {
            const backoff = Math.min(2000 * Math.pow(2, attempt - 1), 30000);
            const jitter = Math.floor(Math.random() * 500);
            const wait = backoff + jitter;
            console.error(`HTTP 429 on ${url} — retrying in ${wait}ms (attempt ${attempt}/${maxAttempts})`);
            await sleep(wait);
            try {
              const t = await httpGetText(url, attempt + 1, maxAttempts);
              return resolve(t);
            } catch (err) {
              return reject(err);
            }
          }
          return reject(new Error(`HTTP ${res.statusCode}: ${data.slice(0,2000)}`));
        });
      });
      req.setTimeout(20000, () => req.destroy(new Error(`Request timed out: ${url}`)));
      req.on('error', (err) => reject(err));
      req.end();
    } catch (err) {
      reject(err);
    }
  });
}

async function getJson(url) {
  const text = await httpGetText(url);
  // when debugging, save raw responses for inspection
  try {
    if (process.env.YVP_DEBUG === '1') {
      const debugDir = path.join(__dirname, 'debug');
      if (!fs.existsSync(debugDir)) fs.mkdirSync(debugDir, { recursive: true });
      const safeName = url.replace(/[^a-z0-9]/gi, '_').slice(0, 180) + '.json';
      const outPath = path.join(debugDir, safeName);
      fs.writeFileSync(outPath, text, 'utf8');
      console.error('  [debug] saved', outPath);
    }
  } catch (err) {
    // ignore debug write errors
  }
  try { return JSON.parse(text); } catch (e) { throw new Error('Non-JSON response: ' + text.slice(0,2000)); }
}

async function listBooks(bibleId) {
  const url = `${API_BASE}/bibles/${bibleId}/books`;
  const json = await getJson(url);
  return json.data || json.books || json;
}

async function listChapters(bibleId, bookId) {
  const url = `${API_BASE}/bibles/${bibleId}/books/${bookId}/chapters`;
  const json = await getJson(url);
  return json.data || json.chapters || json;
}

async function listVerses(bibleId, chapterId, bookId, chapterNumber) {
  const attempts = [];
  // prefer chapter global id
  if (chapterId) {
    attempts.push(`${API_BASE}/chapters/${chapterId}/verses`);
    attempts.push(`${API_BASE}/bibles/${bibleId}/chapters/${chapterId}/verses`);
    if (bookId) attempts.push(`${API_BASE}/bibles/${bibleId}/books/${bookId}/chapters/${chapterId}/verses`);
  }
  // try by chapter number under the book
  if (bookId && chapterNumber != null) {
    attempts.push(`${API_BASE}/bibles/${bibleId}/books/${bookId}/chapters/${chapterNumber}/verses`);
    attempts.push(`${API_BASE}/bibles/${bibleId}/books/${bookId}/verses?chapter=${chapterNumber}`);
  }
  // fallback: verses of a book (may include chapter metadata)
  if (bookId) attempts.push(`${API_BASE}/bibles/${bibleId}/books/${bookId}/verses`);

  for (const url of attempts) {
    try {
      const json = await getJson(url);
      const data = json.data || json.verses || json;
      if (Array.isArray(data) && data.length > 0) return data;
      // if it's an object with nested structure, try to extract array
      if (json && typeof json === 'object') {
        const keys = Object.keys(json);
        for (const k of keys) {
          if (Array.isArray(json[k]) && json[k].length > 0) return json[k];
        }
      }
    } catch (err) {
      // log and try next
      console.error(`    attempt failed: ${url} -> ${err && err.message ? err.message : err}`);
      continue;
    }
  }
  // nothing found
  return [];
}

async function fetchPassageText(passageId, bibleId) {
  if (!passageId) return '';
  const attempts = [];
  attempts.push(`${API_BASE}/bibles/${bibleId}/passages/${encodeURIComponent(passageId)}`);
  // try common passage endpoints
  attempts.push(`${API_BASE}/passages/${encodeURIComponent(passageId)}`);
  attempts.push(`${API_BASE}/passages?passage_id=${encodeURIComponent(passageId)}&bible_id=${bibleId}`);
  attempts.push(`${API_BASE}/passages?ids=${encodeURIComponent(passageId)}&bible_id=${bibleId}`);
  attempts.push(`${API_BASE}/passages/${encodeURIComponent(passageId)}/content`);

  for (const url of attempts) {
    try {
      const json = await getJson(url);
      // try several shapes
      if (!json) continue;
      // direct content
      if (typeof json === 'string' && json.length > 0) return json;
      if (json.content) return (json.content || json.text || '').toString();
      if (json.data && Array.isArray(json.data) && json.data.length > 0) {
        const item = json.data[0];
        if (item.content) return (item.content || '').toString();
        if (item.verse_text) return (item.verse_text || '').toString();
        if (item.text) return (item.text || '').toString();
      }
      // if response has passages mapping
      if (json.passages && Array.isArray(json.passages) && json.passages.length > 0) {
        return (json.passages[0].text || json.passages[0].content || '').toString();
      }
    } catch (err) {
      // continue
      continue;
    }
  }
  return '';
}

function ensureOutDir() {
  if (!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR, { recursive: true });
}

function normalizeBook(book) {
  return {
    id: (book.id || book.book_id || book.bookId || book.abbreviation || book.abbr || book.name).toString(),
    name: book.name || book.book_name || book.bookName || book.title || '',
    abbreviation: book.abbreviation || book.abbr || book.abbrev || '',
  };
}

(async () => {
  try {
    console.error('Listing books for bible', BIBLE_ID);
    const books = await listBooks(BIBLE_ID);
    if (!Array.isArray(books) || books.length === 0) throw new Error('No books returned');

    let pick = books;
    if (!FETCH_ALL && BOOK_QUERY) {
      const q = BOOK_QUERY.toLowerCase();
      pick = books.filter(b => (b.name||'').toLowerCase().includes(q) || (b.abbreviation||'').toLowerCase().includes(q) || (b.id||'').toString() === BOOK_QUERY);
      if (pick.length === 0) {
        console.error('No books matched query:', BOOK_QUERY);
        console.error('Available books:', books.map(b => b.name || b.abbreviation || b.id).join(', '));
        process.exit(2);
      }
    }

    const out = { versionId: String(BIBLE_ID), name: `youversion-${BIBLE_ID}`, books: [] };
    for (const book of pick) {
      const b = normalizeBook(book);
      console.error('Fetching chapters for book:', b.name || b.id);
      // If the book object already contains chapters (and possibly verses), prefer that
      const bookChapters = book.chapters || book.Chapters || book.chapter || book.chapters_list;
      const chOut = [];
      if (Array.isArray(bookChapters) && bookChapters.length > 0) {
        for (const ch of bookChapters) {
          const chapterId = ch.id || ch.chapter_id || ch.chapterId || ch.number || ch.title;
          const vArr = Array.isArray(ch.verses) && ch.verses.length > 0
              ? ch.verses
              : Array.isArray(ch.Verses) && ch.Verses.length > 0
                  ? ch.Verses
                  : [];
          const versesWithText = [];
          const chapterNumber = ch.number || ch.chapter_number || ch.chapter || ch.index || chapterId;
          for (let i = 0; i < vArr.length; i += 8) {
            const batch = vArr.slice(i, i + 8);
            const batchResults = await Promise.all(batch.map(async (v) => {
            let text = v.text || v.content || v.verse || v.body || v.passages || '';
            if (!text) {
              const passageId = v.passage_id || v.passageId || v.passage ||
                `${b.id}.${ch.number}.${v.number}`;
              text = await fetchPassageText(passageId, BIBLE_ID);
            }
            return {
              id: v.id || v.verse_id || v.verseId || v.title || v.number,
              number: v.number || v.verse || v.title || v.verse_number,
              text: text || ''
            };
            }));
            versesWithText.push(...batchResults);
          }
          chOut.push({
            id: chapterId,
            number: chapterNumber,
            verses: versesWithText,
          });
        }
      } else {
        const chapters = await listChapters(BIBLE_ID, book.id || book.book_id || b.id);
        const chArr = Array.isArray(chapters) ? chapters : [];
        for (const ch of chArr) {
          const chapterId = ch.id || ch.chapter_id || ch.chapterId || ch.id;
          console.error('  Fetching verses for chapter id:', chapterId);
          const verses = await listVerses(BIBLE_ID, chapterId, book.id || book.book_id || b.id, ch.number || ch.chapter_number || ch.chapter || ch.index || ch.id);
          const vArr = Array.isArray(verses) ? verses : [];
          const versesWithText = [];
          const chapterNumber = ch.number || ch.chapter_number || ch.chapter || ch.index || ch.id;
          for (let i = 0; i < vArr.length; i += 8) {
            const batch = vArr.slice(i, i + 8);
            const batchResults = await Promise.all(batch.map(async (v) => {
            let text = v.text || v.content || v.verse || v.body || '';
            if (!text) {
              const passageId = v.passage_id || v.passageId || v.passage ||
                `${book.id || book.book_id || b.id}.${ch.number || ch.chapter_number || ch.chapter || ch.index || ch.id}.${v.number || v.verse || v.verse_number}`;
              text = await fetchPassageText(passageId, BIBLE_ID);
            }
            return {
              id: v.id || v.verse_id || v.verseId || v.number,
              number: v.number || v.verse || v.verse_number,
              text: text || ''
            };
            }));
            versesWithText.push(...batchResults);
          }
          chOut.push({
            id: chapterId,
            number: chapterNumber,
            verses: versesWithText,
          });
        }
      }
      out.books.push({ id: b.id, name: b.name, abbreviation: b.abbreviation, chapters: chOut });
    }

    ensureOutDir();
    const filename = path.join(OUT_DIR, `youversion_${BIBLE_ID}.json`);
    fs.writeFileSync(filename, JSON.stringify(out, null, 2), 'utf8');
    console.log('Saved bible asset to', filename);
  } catch (err) {
    console.error('Failed:', err && err.message ? err.message : err);
    process.exit(3);
  }
})();

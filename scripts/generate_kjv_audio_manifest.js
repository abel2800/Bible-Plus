#!/usr/bin/env node
/**
 * Generates assets/catalog/kjv_pdaudio_manifest.json from
 * publicdomainaudiobibles.com KJV HTML (public domain, redistribution allowed).
 */
const https = require('https');
const fs = require('fs');
const path = require('path');

const KJV_HTML = 'https://publicdomainaudiobibles.com/KJV.html';
const BASE_URL = 'https://publicdomainaudiobibles.com/content/mp3/KJV/';

function fetch(url) {
  return new Promise((resolve, reject) => {
    https.get(url, (res) => {
      if (res.statusCode !== 200) {
        reject(new Error(`HTTP ${res.statusCode} for ${url}`));
        return;
      }
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve(data));
    }).on('error', reject);
  });
}

function parseOptions(html) {
  const re = /data-mp3="([^"]+)"[^>]*>([^<]+)/g;
  const books = {};
  let m;
  while ((m = re.exec(html)) !== null) {
    const mp3Path = m[1];
    const label = m[2].trim();
    const labelMatch = label.match(/^(\d+)_(.+?)(\d+)_KJV$/);
    if (!labelMatch) {
      console.warn('Skipping unmatched label:', label);
      continue;
    }
    const bookId = parseInt(labelMatch[1], 10);
    const chapter = parseInt(labelMatch[3], 10);
    if (!books[bookId]) books[bookId] = [];
    books[bookId].push({ chapter, file: path.basename(mp3Path) });
  }
  for (const id of Object.keys(books)) {
    books[id].sort((a, b) => a.chapter - b.chapter);
  }
  return books;
}

async function main() {
  console.log('Fetching', KJV_HTML);
  const html = await fetch(KJV_HTML);
  const books = parseOptions(html);
  const bookEntries = Object.keys(books)
    .map(Number)
    .sort((a, b) => a - b)
    .map((bookId) => ({
      bookId,
      chapters: books[bookId].map((c) => c.file),
    }));

  const manifest = {
    schemaVersion: 1,
    versionId: 'KJV',
    versionAliases: ['WEAHADU_EN_KJV'],
    filesetId: 'kjv-pdaudio-en',
    baseUrl: BASE_URL,
    allowedHosts: ['publicdomainaudiobibles.com', 'www.publicdomainaudiobibles.com'],
    attribution:
      'King James Version audio by Public Domain Audio Bibles (2018). Public domain recording — download, copy, and listen freely.',
    downloadPermitted: true,
    sourcePage: KJV_HTML,
    books: bookEntries,
  };

  const outPath = path.join(
    __dirname,
    '..',
    'assets',
    'catalog',
    'kjv_pdaudio_manifest.json',
  );
  fs.writeFileSync(outPath, JSON.stringify(manifest, null, 2) + '\n');
  const totalChapters = bookEntries.reduce((n, b) => n + b.chapters.length, 0);
  console.log(`Wrote ${outPath}: ${bookEntries.length} books, ${totalChapters} chapters`);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

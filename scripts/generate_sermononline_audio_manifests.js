#!/usr/bin/env node
/**
 * Generates an audio manifest from a sermon-online.com directory listing.
 * Filename pattern: BBCCC-The_Book_Of_Name_Chapter-CCC.mp3
 */
const https = require('https');
const fs = require('fs');
const path = require('path');

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

function parseListing(html) {
  const re = /href="([^"]+\.mp3)"/gi;
  const files = new Set();
  let m;
  while ((m = re.exec(html)) !== null) {
    const href = m[1];
    if (href.includes('Parent') || href.includes('.zip')) continue;
    files.add(path.basename(href));
  }
  return [...files];
}

function buildBooks(filenames) {
  const books = {};
  for (const file of filenames) {
    const match = file.match(/^(\d{2})(\d{3})-/);
    if (!match) {
      console.warn('Skipping:', file);
      continue;
    }
    const bookId = parseInt(match[1], 10);
    const chapter = parseInt(match[2], 10);
    if (!books[bookId]) books[bookId] = {};
    books[bookId][chapter] = file;
  }
  return Object.keys(books)
    .map(Number)
    .sort((a, b) => a - b)
    .map((bookId) => ({
      bookId,
      chapters: Object.keys(books[bookId])
        .map(Number)
        .sort((a, b) => a - b)
        .map((ch) => books[bookId][ch]),
    }));
}

async function generate({
  listingUrl,
  baseUrl,
  outFile,
  versionId,
  versionAliases = [],
  filesetId,
  attribution,
  sourcePage,
}) {
  console.log('Fetching', listingUrl);
  const html = await fetch(listingUrl);
  const filenames = parseListing(html);
  const books = buildBooks(filenames);
  const manifest = {
    schemaVersion: 1,
    versionId,
    versionAliases,
    filesetId,
    baseUrl,
    allowedHosts: ['info2.sermon-online.com'],
    attribution,
    downloadPermitted: true,
    sourcePage,
    books,
  };
  const outPath = path.join(__dirname, '..', 'assets', 'catalog', outFile);
  fs.writeFileSync(outPath, JSON.stringify(manifest, null, 2) + '\n');
  const chapters = books.reduce((n, b) => n + b.chapters.length, 0);
  console.log(`Wrote ${outPath}: ${books.length} books, ${chapters} chapters`);
}

async function main() {
  await generate({
    listingUrl:
      'https://info2.sermon-online.com/amharic/Bible/Amharic-Audio_Bible_Complete_OT_NT_MP3/',
    baseUrl:
      'https://info2.sermon-online.com/amharic/Bible/Amharic-Audio_Bible_Complete_OT_NT_MP3/',
    outFile: 'amh_sermononline_manifest.json',
    versionId: 'AMH',
    versionAliases: [
      'NASV',
      'WEAHADU_AM_2000',
      'WEAHADU_AM_1980',
      'WEAHADU_AM_1962',
      'WEAHADU_AM_NASV_2001',
    ],
    filesetId: 'amh-sermononline',
    attribution:
      'Amharic audio Bible courtesy of Sermon-Online.com. Stream and share freely for personal and ministry use.',
    sourcePage: 'https://www.sermon-online.com/contents/25696',
  });

  await generate({
    listingUrl:
      'https://info2.sermon-online.com/tigrinya/Bible/Tigrinya-Audio_Bible_Complete_New_Testament_NT_MP3/',
    baseUrl:
      'https://info2.sermon-online.com/tigrinya/Bible/Tigrinya-Audio_Bible_Complete_New_Testament_NT_MP3/',
    outFile: 'ti_sermononline_nt_manifest.json',
    versionId: 'WEAHADU_TI_1997',
    versionAliases: ['TIR'],
    filesetId: 'ti-sermononline-nt',
    attribution:
      'Tigrinya New Testament audio courtesy of Sermon-Online.com. Stream and share freely for personal and ministry use.',
    sourcePage: 'https://info2.sermon-online.com/tigrinya/Bible/',
  });
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

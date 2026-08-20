#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const sourceRoot = path.join(repoRoot, 'tmp', '80-weahadu', 'data');
const outputRoot = path.join(repoRoot, 'assets', 'bible');
const editionIds = [
  'am-2000',
  'am-1980',
  'gez-1980',
  'gez-2014',
  'en-kjv',
  'am-nasv-2001',
  'am-1962',
  'ti-1997',
  'om-kitaaba',
];

function normalizeBook(source) {
  return {
    id: source.book,
    name: source.book,
    abbreviation: source.book,
    chapters: (source.chapters || []).map((chapter) => ({
      id: String(chapter.n),
      number: chapter.n,
      verses: (chapter.verses || []).map((verse) => ({
        id: String(verse.n),
        number: verse.n,
        text: verse.t || '',
      })),
    })),
  };
}

function importEdition(editionId) {
  const editionRoot = path.join(sourceRoot, editionId, 'books');
  const files = fs.readdirSync(editionRoot)
    .filter((file) => file.endsWith('.json'))
    .sort();
  const books = files.map((file) =>
    normalizeBook(JSON.parse(fs.readFileSync(path.join(editionRoot, file), 'utf8'))),
  );
  const output = {
    versionId: editionId.toUpperCase().replace(/[^A-Z0-9]+/g, '_'),
    name: editionId,
    books,
  };
  const outputPath = path.join(outputRoot, `weahadu_${editionId}.json`);
  fs.writeFileSync(outputPath, JSON.stringify(output));
  return { outputPath, books };
}

for (const editionId of editionIds) {
  const result = importEdition(editionId);
  const verses = result.books.flatMap((book) =>
    book.chapters.flatMap((chapter) => chapter.verses),
  );
  console.log(`${editionId}: ${result.books.length} books, ${verses.length} verses -> ${result.outputPath}`);
}
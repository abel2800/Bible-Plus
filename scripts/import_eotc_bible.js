#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

function arg(name) {
  const index = process.argv.indexOf(name);
  return index === -1 ? null : process.argv[index + 1];
}

const source = arg('--src');
const output = arg('--out') || path.join('assets', 'bible', 'eotc_80_weahadu.json');

if (!source || !fs.existsSync(source)) {
  console.error('Usage: node scripts/import_eotc_bible.js --src <source.json> [--out <output.json>]');
  process.exit(2);
}

const books = JSON.parse(fs.readFileSync(source, 'utf8'));
if (!Array.isArray(books) || books.length === 0) {
  throw new Error('The source file does not contain a book array.');
}

const normalized = {
  versionId: 'EOTC',
  name: 'Ethiopian Orthodox Bible',
  books: books.map((book) => ({
    id: String(book.book_number),
    name: book.book_name_am || book.book_name_en || '',
    abbreviation: book.book_short_name_am || book.book_short_name_en || '',
    chapters: (book.chapters || []).map((chapter) => ({
      id: String(chapter.chapter),
      number: chapter.chapter,
      verses: (chapter.sections || []).flatMap((section) =>
        (section.verses || []).map((verse) => ({
          id: String(verse.verse),
          number: verse.verse,
          text: verse.text || '',
        })),
      ),
    })),
  })),
};

const outputPath = path.resolve(output);
fs.mkdirSync(path.dirname(outputPath), { recursive: true });
fs.writeFileSync(outputPath, JSON.stringify(normalized, null, 2));
console.log(`Wrote ${normalized.books.length} books to ${outputPath}`);
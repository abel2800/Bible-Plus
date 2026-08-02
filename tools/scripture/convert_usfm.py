#!/usr/bin/env python3
"""Convert a licensed USFM directory to BiblePulse canonical JSON."""

from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

BOOKS = [
    ("GEN", "Genesis"), ("EXO", "Exodus"), ("LEV", "Leviticus"),
    ("NUM", "Numbers"), ("DEU", "Deuteronomy"), ("JOS", "Joshua"),
    ("JDG", "Judges"), ("RUT", "Ruth"), ("1SA", "1 Samuel"),
    ("2SA", "2 Samuel"), ("1KI", "1 Kings"), ("2KI", "2 Kings"),
    ("1CH", "1 Chronicles"), ("2CH", "2 Chronicles"), ("EZR", "Ezra"),
    ("NEH", "Nehemiah"), ("EST", "Esther"), ("JOB", "Job"),
    ("PSA", "Psalms"), ("PRO", "Proverbs"), ("ECC", "Ecclesiastes"),
    ("SNG", "Song of Solomon"), ("ISA", "Isaiah"), ("JER", "Jeremiah"),
    ("LAM", "Lamentations"), ("EZK", "Ezekiel"), ("DAN", "Daniel"),
    ("HOS", "Hosea"), ("JOL", "Joel"), ("AMO", "Amos"),
    ("OBA", "Obadiah"), ("JON", "Jonah"), ("MIC", "Micah"),
    ("NAM", "Nahum"), ("HAB", "Habakkuk"), ("ZEP", "Zephaniah"),
    ("HAG", "Haggai"), ("ZEC", "Zechariah"), ("MAL", "Malachi"),
    ("MAT", "Matthew"), ("MRK", "Mark"), ("LUK", "Luke"),
    ("JHN", "John"), ("ACT", "Acts"), ("ROM", "Romans"),
    ("1CO", "1 Corinthians"), ("2CO", "2 Corinthians"),
    ("GAL", "Galatians"), ("EPH", "Ephesians"), ("PHP", "Philippians"),
    ("COL", "Colossians"), ("1TH", "1 Thessalonians"),
    ("2TH", "2 Thessalonians"), ("1TI", "1 Timothy"),
    ("2TI", "2 Timothy"), ("TIT", "Titus"), ("PHM", "Philemon"),
    ("HEB", "Hebrews"), ("JAS", "James"), ("1PE", "1 Peter"),
    ("2PE", "2 Peter"), ("1JN", "1 John"), ("2JN", "2 John"),
    ("3JN", "3 John"), ("JUD", "Jude"), ("REV", "Revelation"),
]

FOOTNOTE_RE = re.compile(r"\\f\b.*?\\f\*", re.DOTALL)
CROSS_REFERENCE_RE = re.compile(r"\\x\b.*?\\x\*", re.DOTALL)
WORD_RE = re.compile(r"\\w\s+([^|\\]+?)(?:\|[^\\]*?)?\\w\*")
CHAR_MARKER_RE = re.compile(r"\\\+?[a-zA-Z0-9]+\*?(?:\s+)?")
SPACE_RE = re.compile(r"\s+")
CONTINUATION_MARKERS = re.compile(r"^\\(?:q\d*|m|p|pi\d*|li\d*)\s*(.*)$")


def clean_text(value: str) -> str:
    value = FOOTNOTE_RE.sub("", value)
    value = CROSS_REFERENCE_RE.sub("", value)
    value = WORD_RE.sub(lambda match: match.group(1), value)
    value = CHAR_MARKER_RE.sub("", value)
    return SPACE_RE.sub(" ", value).strip()


def source_hash(files: list[Path]) -> str:
    digest = hashlib.sha256()
    for path in files:
        digest.update(path.name.encode("utf-8"))
        digest.update(path.read_bytes())
    return digest.hexdigest()


def parse_book(path: Path, expected_code: str, expected_name: str, book_id: int) -> dict:
    lines = path.read_text(encoding="utf-8-sig").splitlines()
    id_line = next((line for line in lines if line.startswith(r"\id ")), "")
    actual_code = id_line.split(maxsplit=2)[1] if id_line else ""
    if actual_code != expected_code:
        raise ValueError(f"{path.name}: expected {expected_code}, found {actual_code}")

    chapters: dict[int, dict[int, list[str]]] = {}
    chapter_number: int | None = None
    verse_number: int | None = None

    for line in lines:
        chapter_match = re.match(r"^\\c\s+(\d+)", line)
        if chapter_match:
            chapter_number = int(chapter_match.group(1))
            verse_number = None
            chapters.setdefault(chapter_number, {})
            continue

        verse_match = re.match(r"^\\v\s+(\d+)(?:-\d+)?\s*(.*)$", line)
        if verse_match and chapter_number is not None:
            verse_number = int(verse_match.group(1))
            chapter = chapters[chapter_number]
            if verse_number in chapter:
                raise ValueError(
                    f"{expected_code} {chapter_number}:{verse_number} is duplicated"
                )
            chapter[verse_number] = [verse_match.group(2)]
            continue

        continuation = CONTINUATION_MARKERS.match(line)
        if (
            continuation
            and chapter_number is not None
            and verse_number is not None
            and continuation.group(1)
        ):
            chapters[chapter_number][verse_number].append(continuation.group(1))

    if not chapters:
        raise ValueError(f"{expected_code}: no chapters found")

    output_chapters = []
    for expected_chapter, chapter_number in enumerate(sorted(chapters), start=1):
        if chapter_number != expected_chapter:
            raise ValueError(
                f"{expected_code}: expected chapter {expected_chapter}, found {chapter_number}"
            )
        verses = []
        for number in sorted(chapters[chapter_number]):
            text = clean_text(" ".join(chapters[chapter_number][number]))
            if not text:
                print(
                    f"Skipping intentionally empty {expected_code} "
                    f"{chapter_number}:{number}"
                )
                continue
            verses.append({"verse": number, "text": text})
        output_chapters.append({"number": chapter_number, "verses": verses})

    return {
        "id": book_id,
        "code": expected_code,
        "name": expected_name,
        "testament": "OT" if book_id <= 39 else "NT",
        "chapters": output_chapters,
    }


def load_manifest(path: Path) -> dict:
    manifest = json.loads(path.read_text(encoding="utf-8"))
    required = {
        "id",
        "name",
        "language",
        "source",
        "license",
        "attribution",
        "commercialUse",
        "redistribution",
        "approved",
    }
    missing = required.difference(manifest)
    if missing:
        raise ValueError(f"Manifest missing: {', '.join(sorted(missing))}")
    if not (
        manifest["approved"]
        and manifest["redistribution"]
        and manifest["commercialUse"]
    ):
        raise ValueError("Manifest does not approve app-store redistribution")
    return manifest


def convert(source: Path, output: Path, manifest_path: Path) -> None:
    manifest = load_manifest(manifest_path)
    files = sorted(source.glob("*.usfm"))
    by_code: dict[str, Path] = {}
    for path in files:
        match = re.search(r"([123]?[A-Z]{2,3})[^/\\]*\.usfm$", path.name)
        if match:
            by_code[match.group(1)] = path

    missing = [code for code, _ in BOOKS if code not in by_code]
    if missing:
        raise ValueError(f"Missing canonical books: {', '.join(missing)}")

    books = [
        parse_book(by_code[code], code, book_name, index)
        for index, (code, book_name) in enumerate(BOOKS, start=1)
    ]
    verse_count = sum(
        len(chapter["verses"])
        for book in books
        for chapter in book["chapters"]
    )
    payload = {
        "schemaVersion": 1,
        "translation": {
            "id": manifest["id"],
            "name": manifest["name"],
            "language": manifest["language"],
            "canon": manifest.get("canon", "protestant-66"),
            "source": manifest["source"],
            "license": manifest["license"],
            "attribution": manifest["attribution"],
            "rightsExpiresAt": manifest.get("expiresAt"),
            "sourceSha256": source_hash([by_code[code] for code, _ in BOOKS]),
        },
        "statistics": {"books": len(books), "verses": verse_count},
        "books": books,
    }

    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    print(f"Wrote {len(books)} books and {verse_count} verses to {output}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--manifest", required=True, type=Path)
    args = parser.parse_args()

    try:
        convert(args.source, args.output, args.manifest)
    except (OSError, ValueError, json.JSONDecodeError) as error:
        print(f"Conversion failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

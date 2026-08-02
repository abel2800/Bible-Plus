"""Fetch public-domain KJV/ASV from midvash/bible-data and normalize to BiblePulse schema."""
from __future__ import annotations

import hashlib
import json
import urllib.request
from pathlib import Path

UA = {"User-Agent": "BiblePulseContentFetch/1.0"}
ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = ROOT / "assets" / "bible"

SOURCES = {
    "KJV": {
        "url": "https://raw.githubusercontent.com/midvash/bible-data/main/versions/en/kjv/kjv.json",
        "name": "King James Version",
        "source": "https://github.com/midvash/bible-data",
    },
    "ASV": {
        "url": "https://raw.githubusercontent.com/midvash/bible-data/main/versions/en/asv/asv.json",
        "name": "American Standard Version",
        "source": "https://github.com/midvash/bible-data",
    },
}


def fetch(url: str) -> bytes:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=120) as resp:
        return resp.read()


def normalize(version_id: str, meta: dict, raw: dict) -> dict:
    books_out = []
    for index, book in enumerate(raw.get("books") or [], start=1):
        book_id = int(book.get("bookId") or index)
        name = (
            book.get("englishName")
            or book.get("name")
            or book.get("book")
            or f"Book {book_id}"
        )
        chapters_out = []
        for chapter in book.get("chapters") or []:
            number = int(chapter.get("chapter") or chapter.get("number") or 0)
            verses_out = []
            for verse in chapter.get("verses") or []:
                if isinstance(verse, dict):
                    vnum = int(verse.get("number") or verse.get("verse") or 0)
                    text = str(verse.get("text") or "").strip()
                else:
                    continue
                if vnum < 1 or not text:
                    continue
                verses_out.append({"verse": vnum, "text": text})
            if number < 1 or not verses_out:
                continue
            chapters_out.append({"number": number, "verses": verses_out})
        if not chapters_out:
            continue
        books_out.append(
            {
                "id": book_id,
                "name": name,
                "testament": "OT" if book_id <= 39 else "NT",
                "chapters": chapters_out,
            }
        )

    return {
        "schemaVersion": 1,
        "translation": {
            "id": version_id,
            "name": meta["name"],
            "language": "en",
            "source": meta["source"],
            "license": "Public Domain",
        },
        "books": books_out,
    }


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for version_id, meta in SOURCES.items():
        print(f"Fetching {version_id}…", flush=True)
        payload = fetch(meta["url"])
        source_sha = hashlib.sha256(payload).hexdigest()
        raw = json.loads(payload.decode("utf-8"))
        normalized = normalize(version_id, meta, raw)
        normalized["translation"]["sourceSha256"] = source_sha
        out = OUT_DIR / f"{version_id.lower()}.json"
        text = json.dumps(normalized, ensure_ascii=False, separators=(",", ":"))
        out.write_text(text + "\n", encoding="utf-8")
        asset_sha = hashlib.sha256(out.read_bytes()).hexdigest()
        verse_count = sum(
            len(v["verses"])
            for b in normalized["books"]
            for v in b["chapters"]
        )
        print(
            f"  wrote {out.name} books={len(normalized['books'])} "
            f"verses={verse_count} bytes={out.stat().st_size} sha256={asset_sha}"
        )


if __name__ == "__main__":
    main()

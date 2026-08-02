"""Scrape eBible WEB Henson audio indexes into a chapter URL manifest."""
from __future__ import annotations

import json
import re
import time
import urllib.parse
import urllib.request
from pathlib import Path

UA = {"User-Agent": "Mozilla/5.0 BiblePulseManifestBuilder/1.0 (content licensing check)"}
BASE = "https://ebible.org/eng-web/audio/"

# Protestant canon folder names on eBible (66 books).
BOOK_FOLDERS = [
    "01_Genesis",
    "02_Exodus",
    "03_Leviticus",
    "04_Numbers",
    "05_Deuteronomy",
    "06_Joshua",
    "07_Judges",
    "08_Ruth",
    "09_First_Samuel",
    "10_Second_Samuel",
    "11_First_Kings",
    "12_Second_Kings",
    "13_First_Chronicles",
    "14_Second_Chronicles",
    "15_Ezra",
    "16_Nehemiah",
    "17_Esther",
    "18_Job",
    "19_Psalms",
    "20_Proverbs",
    "21_Ecclesiastes",
    "22_Song_of_Solomon",
    "23_Isaiah",
    "24_Jeremiah",
    "25_Lamentations",
    "26_Ezekiel",
    "27_Daniel",
    "28_Hosea",
    "29_Joel",
    "30_Amos",
    "31_Obadiah",
    "32_Jonah",
    "33_Micah",
    "34_Nahum",
    "35_Habakkuk",
    "36_Zephaniah",
    "37_Haggai",
    "38_Zechariah",
    "39_Malachi",
    "40_Matthew",
    "41_Mark",
    "42_Luke",
    "43_John",
    "44_Acts",
    "45_Romans",
    "46_First_Corinthians",
    "47_Second_Corinthians",
    "48_Galatians",
    "49_Ephesians",
    "50_Philippians",
    "51_Colossians",
    "52_First_Thessalonians",
    "53_Second_Thessalonians",
    "54_First_Timothy",
    "55_Second_Timothy",
    "56_Titus",
    "57_Philemon",
    "58_Hebrews",
    "59_James",
    "60_First_Peter",
    "61_Second_Peter",
    "62_First_John",
    "63_Second_John",
    "64_Third_John",
    "65_Jude",
    "66_Revelations",
]


def fetch(url: str) -> str:
    req = urllib.request.Request(url, headers=UA)
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read().decode("utf-8", "replace")


def chapter_files(folder: str) -> list[str]:
    html = fetch(f"{BASE}{folder}/")
    links = re.findall(r'href="([^"?]+\.mp3)"', html, re.I)
    # Keep order as listed. Skip duplicate uploads like "Chapter Seventeen (1).mp3".
    out: list[str] = []
    seen: set[str] = set()
    for link in links:
        decoded = urllib.parse.unquote(link)
        if "(1)" in decoded or "(2)" in decoded:
            continue
        if link in seen:
            continue
        seen.add(link)
        out.append(link)
    return out


def main() -> None:
    books: list[dict] = []
    for i, folder in enumerate(BOOK_FOLDERS, start=1):
        print(f"[{i:02d}/66] {folder}", flush=True)
        try:
            files = chapter_files(folder)
        except Exception as exc:  # noqa: BLE001
            print(f"  ERROR {exc}")
            files = []
        books.append(
            {
                "bookId": i,
                "folder": folder,
                "chapters": files,
            }
        )
        time.sleep(0.15)

    manifest = {
        "schemaVersion": 1,
        "versionId": "WEB",
        "filesetId": "web-henson-ebible",
        "baseUrl": BASE,
        "attribution": (
            "World English Bible audio narrated by Winfred W. Henson. "
            "Public domain recording via eBible.org — download, copy, and listen freely."
        ),
        "downloadPermitted": True,
        "sourcePage": "https://ebible.org/eng-web/audio/",
        "books": books,
    }

    out = Path(__file__).resolve().parents[1] / "assets" / "catalog" / "web_henson_audio_manifest.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    total = sum(len(b["chapters"]) for b in books)
    empty = [b["folder"] for b in books if not b["chapters"]]
    print(f"Wrote {out} chapters={total} empty_books={empty}")


if __name__ == "__main__":
    main()

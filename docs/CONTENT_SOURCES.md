# BiblePulse Content Sources

Only content with verified redistribution terms may be enabled in BiblePulse.
Every shipped payload must appear in `assets/content_manifest.json` with an
approved commercial-redistribution flag, attribution, expiry (when applicable),
and exact SHA-256. CI runs `tools/content/validate_manifest.py` and rejects
unlisted files or checksum changes.

## World English Bible

- App translation ID: `WEB`
- Edition: World English Bible, 66-book Protestant edition
- Upstream ID: `engwebp`
- Language: English
- Source page: <https://ebible.org/engwebp/>
- Source archive: <https://ebible.org/scriptures/engwebp_usfm.zip>
- Retrieved: July 17, 2026
- Archive SHA-256:
  `4253589697DC6B5E92695655F2F28792D50E7BE7B9C8E212AF4F4BD18E866C3B`
- License: Public Domain
- Trademark condition: modified text must not be represented as the World
  English Bible.

The bundled JSON contains normalized Scripture text, not invented fallback
verses. USFM study metadata and footnotes are removed without changing the
displayed verse wording. Intentionally empty source verse markers are omitted
rather than populated with fabricated text.

Rebuild:

```powershell
powershell -ExecutionPolicy Bypass -File tools/scripture/fetch_web.ps1
```

The conversion output is `assets/bible/web.json`. Converter metadata is read
from `tools/scripture/manifests/web.json`; it refuses manifests that do not
approve app-store redistribution. The downloaded source
archive and expanded upstream files are reproducible working files and are not
committed.

## King James Version / American Standard Version

- App translation IDs: `KJV`, `ASV`
- License: Public Domain
- Upstream packaging: [midvash/bible-data](https://github.com/midvash/bible-data)
- Shipped as optional installable assets (`assets/bible/kjv.json`,
  `assets/bible/asv.json`) so Bible Store installs work on web and native
  without broken remote URLs
- Rebuild: `python tools/scripture/fetch_kjv_asv.py`

These packs are listed in the Bible Store and install on demand (they are not
auto-bundled like WEB).

## Amharic Bible

Status: not bundled; online via Bible Brain when configured.

Most widely used Amharic texts are copyrighted (e.g. UBS/BSE). BiblePulse does
not ship Amharic JSON in the app package.

**Preferred path:** Digital Bible Platform / Bible Brain (`https://4.dbt.io/`).

1. Request an API key: <https://4.dbt.io/api_key/request>
2. Build with `BIBLE_BRAIN_API_KEY` (never commit the key)
3. Open Bible Store — Amharic (and other languages your key can access) appear
   as streamable `bible_brain` packages
4. Tap **Enable online**, then set as preferred translation

OpenAPI: <https://4.dbt.io/open-api-4.json>

For audio, also set `BIBLE_BRAIN_BIBLE_IDS_JSON` and `BIBLE_BRAIN_MEDIA_HOSTS`
(see `docs/INTEGRATIONS_AND_RELEASE.md`). Download/offline audio only when
`/download/list` marks the fileset as permitted for your key.

Bundled redistribution of Amharic still requires written permission recorded in
`assets/content_manifest.json` before any offline package is approved.

Reference (eBible Amharic NT terms): <https://ebible.org/amh/copyright.htm>

## WEB audio Bible (Henson / eBible)

- App audio fileset ID: `web-henson-ebible`
- Translation: World English Bible (`WEB`)
- Narrator: Winfred W. Henson
- Source page: <https://ebible.org/eng-web/audio/>
- License: Public domain recording; eBible states you may download, copy, and
  listen freely. The WEB text itself is public domain.
- Delivery: chapter MP3s streamed over HTTPS from `ebible.org` (not bundled)
- Chapter URL index: `assets/catalog/web_henson_audio_manifest.json`
  (regenerate with `python tools/build_web_henson_audio_manifest.py`)

BiblePulse enables this resolver by default when Bible Brain credentials are
not configured. Playback uses the existing audio cache when downloads are
permitted.

Optional Bible Brain filesets remain available when
`BIBLE_BRAIN_API_KEY`, `BIBLE_BRAIN_BIBLE_IDS_JSON`, and
`BIBLE_BRAIN_MEDIA_HOSTS` are set at build time (see
`docs/INTEGRATIONS_AND_RELEASE.md`).

## Devotionals, plans, and hymns

Author-content catalogs remain capability-gated until API access/content
rights, attribution, caching, and redistribution terms are recorded here.

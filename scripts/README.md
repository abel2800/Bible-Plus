Fetch and add YouVersion / Bible Brain bibles

This folder contains helper scripts used to fetch Bible text from the YouVersion/Bible Brain API
and import them into the app as offline JSON assets.

Scripts
- `fetch_youversion_bible.js` — fetches bible books/chapters/verses and writes a JSON asset to `assets/bible/` (use `YVP_DEBUG=1` to save raw API responses to `scripts/debug/`).
- `add_local_bible_asset.js` — copies a local bible JSON into `assets/bible/`, updates `assets/catalog/bible_catalog.json`, and adds the asset to `pubspec.yaml`.
- `fetch_and_add_bible.js` — convenience wrapper that runs the fetch script then automatically calls the add script.

Quick example (PowerShell):

```powershell
$env:YVP_KEY="(your-api-key)"
$env:YVP_DEBUG=1
node scripts/fetch_and_add_bible.js --bible 4125 --version ORM --all
```

Notes
- Keep your API key secret; rotate/revoke after use.
- If the rights-holder does not permit redistribution, do not bundle the asset; instead use streaming via Bible Brain by setting `BIBLE_BRAIN_API_KEY` and `BIBLE_BRAIN_BIBLE_IDS_JSON` at runtime.
- After adding an asset run `flutter pub get` and rebuild the app.

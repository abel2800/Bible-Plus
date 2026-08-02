# Home screen widget (cross-platform notes)

## What works on every platform

These pieces are pure Flutter and ship on **Android, iOS, web, Windows, Linux, macOS**:

- Reading heatmap on Home
- Staggered entrance animations (`flutter_animate`)
- Capability intro sheet + gated-feature badges
- Original SVG illustrations

## Native home-screen widget

| Platform | Status |
|---|---|
| Android | Fully wired (`BiblePulseWidgetProvider`) |
| iOS | Dart ready; needs Xcode Widget Extension once |
| Web / Windows / Linux / macOS | No OS home widget API — `HomeWidgetService` no-ops safely |

### Android (done in repo)

1. Build/run the app and open Home once (writes verse + streak).
2. Long-press home screen → Widgets → **BiblePulse** → add Verse of the Day.

### iOS (one-time Xcode work)

1. Open `ios/Runner.xcworkspace` in Xcode.
2. **File → New → Target → Widget Extension**, name `BiblePulseWidget`.
3. Add App Group `group.app.biblepulse.reader` to Runner + widget.
4. Read keys `verse_text`, `verse_reference`, `streak` from
   `UserDefaults(suiteName: "group.app.biblepulse.reader")`.
5. `HomeWidgetService.configure()` already calls `setAppGroupId` on iOS.

Until the extension exists, iOS builds still succeed; widget sync is skipped
if the extension is missing.

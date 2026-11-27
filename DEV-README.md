# Inkstone — development assets (Android-only Flutter app)

| Folder | What |
|---|---|
| flutter_app/ | Flutter Android project: theme, motion widgets, 21 screens, go_router, smoke tests |
| engine/ | Offline Dart chart engine (BaZi, Kua, Flying Stars, almanac) + 24 unit tests — **verify against known charts before shipping** |
| content/ | JSON content: 78 tarot cards, 40 crystals, 30 rituals, forecast templates, Kua, Flying Stars |
| proxy/ | AI prompts + JSON schemas (8 tasks) and a stateless Cloudflare Worker that stores and logs nothing |
| store/ | Play listing, privacy policy, disclaimer, Data safety answers |
| spend.json | Claude API spend ledger for this job |

Generated with Claude (claude-opus-5-5) and checked on the build box: `flutter analyze` (0 errors/warnings), `flutter test` (42 pass), `dart test` engine (24 pass), `tsc --noEmit` worker (pass), all JSON parsed.

## Uploading to GitHub in the browser
GitHub web upload takes max 100 files and 25 MB per file per upload, and keeps folders when you drag folders in.
1. Unzip each part zip on your computer.
2. In github.com/bhemfine/Fengshui choose **Add file → Upload files**, drag the unzipped folder (e.g. `flutter_app`) into the page, commit.
3. Repeat per part. `flutter_app` is split into two zips (`flutter_app-1` = lib/test/config, `flutter_app-2` = android/) so each upload stays under 100 files.

## Quick check, direction calculator and home checklist (Nov 2026)
- Engine: `engine/lib/src/home_facing.dart` (degrees → 8 directions / 24 Mountains with 3° line-facing flag, period from completion year, couple match, tilt-compensated compass maths) and `engine/lib/src/home_checklist.dart` (rule model + evaluator). Kua uses the PLAN.md mod-9 formula on the Li Chun solar year.
- Content: `content/home_checklist.json` (76 rules, tagged classical / Black Hat / popular / practical; HDB-safe cures). A byte-identical copy is bundled at `flutter_app/assets/content/home_checklist.json`; an engine test fails if they drift.
- App routes: `/quick-check`, `/quick-check-result`, `/direction-calculator`, `/home-checklist` (House tab; entry cards on Floor upload and House check).
- Storage: checklist answers and last property type only, in SharedPreferences on the phone. Android backup and device transfer are off (`allowBackup=false`, `data_extraction_rules.xml`). Quick-entry birthdays are never stored.
- Checked on the PC: `flutter analyze` 0 errors/warnings (50 info: material.dart deprecation), `flutter test` 55 pass, engine `dart test` 49 pass, `flutter build apk --release --split-per-abi` (debug-key signed).

## Map bearing and example couple (Nov 2026)
- `/map-bearing` (from Direction calculator → Map bearing): flutter_map with OneMap / OSM / Esri satellite tiles, Nominatim address search (keyless), north-up, pin + facing point → bearing (`engine/lib/src/geo.dart`). INTERNET permission added to the main manifest; no location permission.
- Example profiles: Chua Boon Eng (26 Jun 1990, M, Kua 1 East) and Chou Jiahui Victoria (28 Oct 1991, F, Kua 6 West).
- Checked on the box (Flutter 3.50.1): `flutter analyze` 0 errors/warnings (52 info, material.dart deprecation), `flutter test` 61 pass, engine `dart test` 54 pass.

## Listing link import and example couple only (Nov 2026)
- Engine: `engine/lib/src/listing_import.dart` — `parseListingUrl` (PropertyGuru slug and `/l/<id>` short link, 99.co slug, HDB Flat Portal resale id), `parseListingHtml` (JSON-LD, `__NEXT_DATA__`, og:, 99.co rows and floor-plan items), `parseListingText` (rendered page text), `looksBlocked`. Fixtures in `engine/test/fixtures/listing/` are trimmed real pages with agent names, phone numbers, CEA numbers and descriptions removed. Also `luckPillarsFor` in `bazi.dart`.
- App: `/listing-import` (House tab "Paste a listing link", quick check button, Android share of a text/plain link via `MainActivity` → `com.inkstone.app/share`). `lib/data/listing_fetch.dart` (plain fetch from the phone, follows redirects, block detection, Nominatim geocode), `lib/widgets/listing_render_view.dart` (visible WebView fallback; clears cookies, cache and storage after), `lib/data/home_plan_store.dart` (floor plan in the app documents folder). Quick check takes a `QuickCheckPrefill`; the facing is never pre-filled. `/map-bearing` takes `MapBearingArgs` (centre, search text, facing hint).
- New packages: webview_flutter, path_provider, image_picker.
- Examples: only Chua Boon Eng (main user) and Chou Jiahui Victoria (partner). BaZi, compatibility, house check and quick check verdicts are computed by the engine (`lib/data/example_charts.dart`).
- Site status (tested Nov 2026): 99.co pages read with a plain fetch. PropertyGuru answers a plain fetch with a Cloudflare 403, including `/l/<id>` (no redirect is sent before the challenge), so the phone falls back to the WebView. HDB Flat Portal is a JavaScript app with no public JSON API found, so it always uses the WebView.

## Your year, lucky lists and year afflictions (v4, Nov 2026)
- Engine: `engine/lib/src/zodiac_year.dart` (Na Yin 60 table, `zodiacForBirth`, `taiSuiReading`, `yearAfflictions`) and `engine/lib/src/lucky.dart` (`luckyProfile`: colours, He Tu numbers, Kua directions with annual cautions, crystals and rituals by tag). Fixed `Mountain.centreDegree` (壬 345°, 子 0°).
- Content: `forecast_templates.json`, `crystals.json`, `rituals.json` bundled byte-identical under `flutter_app/assets/content/` (engine and app tests fail on drift). Loaded by `lib/data/content_repo.dart`.
- App: `lib/data/your_year.dart`, `lib/data/current_home.dart` (in-memory home from the last quick check, labelled example otherwise), `widgets/year_afflictions_card.dart`. Today, Month, Your year, BaZi and compatibility screens call the engine; `samplePalaces` and the leftover sample almanac data are gone.
- Checked on the box (Flutter 3.50.1): `flutter analyze` 0 errors/warnings (59 info), `flutter test` 75 pass, engine `dart test` 96 pass.

## Tarot (offline, Nov 2026)
- Pack: `content/tarot/readings.json` (78 cards), `classifier.json`, `spreads.json`, bundled under `flutter_app/assets/content/tarot/`. Seed short meanings remain in `major_arcana.json`, `wands_cups.json` and `swords_pentacles.json`.
- App: `lib/data/tarot_catalog.dart`, `tarot_classifier.dart`, `tarot_reading.dart`, `screens/tarot_screen.dart`, `widgets/tarot_deck.dart`. Question classification and reading composition run only on the phone. No network call.
- Copy was drafted at build time with Claude Sonnet 5.5 (no user questions were sent). Have a practitioner review before launch. Card art is not included; fronts are typography.
- Tests: `flutter_app/test/tarot_test.dart`.

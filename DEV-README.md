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
- Example profiles: Chua Boon Eng (26 Jun 1990, M, Kua 1 East) and Chou Jiahui Victoria (28 Oct 1991, F, Kua 6 West), plus Mei Lin and Wei Hao.
- Checked on the box (Flutter 3.50.1): `flutter analyze` 0 errors/warnings (52 info, material.dart deprecation), `flutter test` 61 pass, engine `dart test` 54 pass.

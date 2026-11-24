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

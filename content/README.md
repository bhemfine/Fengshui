# Inkstone content (JSON, English with Chinese terms + pinyin + translation)

| File | Contents |
|---|---|
| tarot/major_arcana.json | Seed pack: 22 major-arcana cards (short meanings) |
| tarot/wands_cups.json | Seed pack: 28 minor-arcana cards |
| tarot/swords_pentacles.json | Seed pack: 28 minor-arcana cards |
| tarot/readings.json | App pack: all 78 cards, upright and reversed texts for summary, love, career, money, health, family, general, yes/no, timing, advice, plus a short thread clause. Drafted at build time; the app never sends a user question to a model |
| tarot/classifier.json | On-device keyword and phrase lists (English, Singlish, pinyin) that map a question to a topic and to yes/no or timing flags |
| tarot/spreads.json | One-card and two three-card spreads, openers, position intros and closings |
| crystals.json | 40 crystal profiles |
| rituals.json | 30 rituals ("potions") with steps and safety notes |
| forecast_templates.json | daily score bands, 12 day officers, 16 activity tags, 12 monthly themes, yearly 2026 + 2027 for all 12 animals |
| kua_directions.json | Kua 1–9 and 8 direction types with HDB tips |
| flying_stars.json | stars 1–9, 30 combinations, 2026/2027 annual notes |
| home_checklist.json | 76 rule-based home checks (All homes, HDB, Condo, Landed, Buying stage, Reno tips), each tagged by school, with HDB-safe cures. A copy is bundled in `flutter_app/assets/content/` (engine test checks they match) |
| manifest.json | file list and expected counts |

All files parse as strict JSON and match the expected counts. AI-drafted: have a practitioner review the wording before launch. For entertainment and reflection only.

# Ultimate Feng Shui App

A personal feng shui and destiny app for Android first (iOS later from the same code). First market: Singapore and Malaysia, in English and Chinese.

The app knows you, your family and your home, and turns classical Chinese metaphysics into clear, personal, daily advice. Feng shui and BaZi are the credible core. Palm reading, tarot, horoscopes, crystals and rituals are add-on modules. Verified masters can also offer teleconsulting later, with optional remedy prescriptions the user is free to buy or skip.

**Core principle:** Charts and rules are calculated by exact code on the device, never guessed by AI. AI only reads photos and explains results in plain language, and every reading cites the rule it is based on.

**Data principle:** This is a local-first app. All personal data (profile, birth details, family, charts, readings, floor plans, photos, tarot history and settings) stays on the user's phone, in an encrypted on-device database. The operator does not keep that data. There is no Supabase or other hosted user database for the core product. Online calls (vision AI, written readings, Google Maps) go through a small stateless proxy that hides API keys and does not store what was sent. Backup is optional and user-owned (an encrypted file, or the user's own Google Drive). A small self-hosted server (recommended: PocketBase on a VPS) is needed only later, for the master marketplace, and then only for minimal booking records.

Default schools: Flying Stars (Xuan Kong) and Eight Mansions (Ba Zhai) for homes, Four Pillars (BaZi) for people.

This repository starts as the product and technical plan so it can be built (intended implementer: GitHub user **bhemfine**). The working title is still an open decision. The approved UI prototype uses the temporary name **Inkstone**.

## Modules

1. Personal profile and chart engine
2. Home and floor plan analyser
3. House hunting with Google Maps
4. Relationships and compatibility
5. Daily, monthly and yearly forecasts
6. Ask the Master
7. Palm and face reading
8. Tarot, horoscope and I Ching
9. Crystals, rituals and remedies
10. Master teleconsulting marketplace (later; minimal-data server)

## Docs

- **[PLAN.md](PLAN.md)** — the full developer-ready specification: vision, local-first architecture, recommended tech stack, how each module works, user stories, screens, on-device operations and proxy calls, data model (device vs marketplace), monetisation, privacy and Play Store rules, engineering development phases, feature rollout, risks, and the Phase 1 MVP build checklist.
- **[DESIGN.md](DESIGN.md)** — the approved visual system (midnight astrolabe, champagne gold `#bfa577` / `#e3d6b8`, ivory, twinkling starfield) taken from the clickable prototype in `fengshui-ui-v3`, for matching in Flutter.

Do not treat prices, commissions or running costs as decided. The only known fee in the plan is the one-time Google Play developer account fee of USD 25. That account is not needed until the closed test at the end of the first version.

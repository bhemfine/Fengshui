# Tarot pack

`readings.json` is the pack the app loads (78 cards). `classifier.json` and `spreads.json` drive on-device question tagging and spread wording. The three seed files (`major_arcana.json`, `wands_cups.json`, `swords_pentacles.json`) kept the short draft meanings used as input.

The longer texts were drafted at build time with Claude Sonnet 5.5 on 27 Nov 2026 (about USD 0.69 of API use). No user question or personal data was sent. The running app never calls a model: it classifies the question on the phone and composes the reading from this bundled JSON.

Have a practitioner review the wording before launch. For entertainment and reflection only. Card art is not included; do not add unlicensed deck scans.

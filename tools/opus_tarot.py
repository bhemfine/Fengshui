#!/usr/bin/env python3
"""Rewrite Inkstone tarot readings.json with Opus 5.5. Schema stays compatible.

No user data is sent. Shares the spend log at /tmp/opus-enrich/spend.json.
"""
from __future__ import annotations

import json, os, sys, re, urllib.request, urllib.error
from pathlib import Path

# Reuse helpers by importing from opus_content
sys.path.insert(0, str(Path(__file__).resolve().parent))
from opus_content import (  # type: ignore
    MODEL, HARD_STOP_USD, ROOT, call_claude, tool_input, spend_record, PLACEHOLDER_RE,
)

SRC = ROOT / "content" / "tarot" / "readings.json"
DEST = ROOT / "flutter_app" / "assets" / "content" / "tarot" / "readings.json"
FIELDS = [
    "summary", "love", "career", "money", "health", "family",
    "general", "yes_no", "timing", "advice", "thread",
]
MIN_LEN = {
    "thread": 20,
}
# 3–5 sentences for most fields; thread is a short clause
SENT_RE = re.compile(r"[.!?]+")

SYSTEM = """You rewrite original tarot interpretations for Inkstone, a calm Singapore/Malaysia Android app (English).

Rules:
- Write original wording. Do not copy Rider–Waite, Crowley, or any published deck, or paste the seed lines verbatim (you may keep their sense).
- Tone: plain, warm, specific, adult. No mysticism for its own sake, no fortune guarantees, no medical/legal/financial advice, no death or illness predictions, no telling anyone to leave a partner, quit a job, or spend money.
- For every field except 'thread': write 3–5 complete sentences (about 280–700 characters). Be detailed and practical.
- 'thread' is a short clause (6–14 words) that can follow 'this card points to'.
- Categories: summary, love, career, money, health (wellbeing/energy, not diagnosis), family (home and family), general, yes_no (prose that leans yes, no, or mixed, matching the given yes_no_lean), timing (pace and seasons, not a calendar date), advice, thread.
- Upright and reversed must clearly differ. Reversed is a delay, excess, or inner work — not a curse.
- Singapore context is fine when natural. Keep each card's id unchanged.
- Return only a tool call.
"""

TOOL = {
    "name": "save_tarot_cards",
    "description": "Save rewritten upright and reversed texts for a few cards.",
    "input_schema": {
        "type": "object",
        "required": ["cards"],
        "properties": {
            "cards": {
                "type": "array",
                "items": {
                    "type": "object",
                    "required": ["id", "upright", "reversed"],
                    "properties": {
                        "id": {"type": "string"},
                        "upright": {"type": "object"},
                        "reversed": {"type": "object"},
                    },
                },
            }
        },
    },
}


def field_errors(card_id: str, orient: str, block: dict) -> list[str]:
    errs = []
    if not isinstance(block, dict):
        return [f"{card_id}.{orient} missing"]
    for f in FIELDS:
        v = block.get(f)
        if not isinstance(v, str) or not v.strip():
            errs.append(f"{card_id}.{orient}.{f} empty")
            continue
        text = v.strip()
        if PLACEHOLDER_RE.search(text):
            errs.append(f"{card_id}.{orient}.{f} placeholder")
        if f == "thread":
            wc = len(text.split())
            if wc < 5 or wc > 18:
                errs.append(f"{card_id}.{orient}.thread words={wc}")
            continue
        if len(text) < 160:
            errs.append(f"{card_id}.{orient}.{f} short ({len(text)})")
        sents = [s for s in SENT_RE.split(text) if s.strip()]
        if len(sents) < 3:
            errs.append(f"{card_id}.{orient}.{f} sentences={len(sents)}")
    return errs


def card_ok(card: dict, rewritten: dict) -> list[str]:
    errs = []
    for orient in ("upright", "reversed"):
        errs.extend(field_errors(card.get("id"), orient, rewritten.get(orient) or {}))
    return errs


def already_rich(card: dict) -> bool:
    return not card_ok(card, card)


def write_tarot(limit=None):
    data = json.loads(SRC.read_text())
    cards = data["cards"]
    by_id = {c["id"]: i for i, c in enumerate(cards)}
    pending = [c for c in cards if not already_rich(c)]
    if limit:
        pending = pending[:limit]
    print(f"{len(pending)} cards to rewrite, {len(cards)-len(pending)} already rich")
    # 3 cards per call
    for i in range(0, len(pending), 3):
        rec = spend_record()
        if rec["total_usd"] >= HARD_STOP_USD:
            print("hard stop")
            break
        batch = pending[i:i+3]
        seeds = []
        for c in batch:
            seeds.append({
                "id": c["id"],
                "name": c["name"],
                "arcana": c.get("arcana"),
                "suit": c.get("suit"),
                "yes_no_lean": c.get("yes_no_lean"),
                "keywords_upright": c.get("keywords_upright"),
                "keywords_reversed": c.get("keywords_reversed"),
                "seed_upright": {f: (c.get("upright") or {}).get(f) for f in FIELDS},
                "seed_reversed": {f: (c.get("reversed") or {}).get(f) for f in FIELDS},
            })
        user = (
            "Rewrite these cards in more detail. Keep each id. "
            "yes_no prose must match yes_no_lean. Seed texts are only a sense, not wording to copy:\n"
            + json.dumps(seeds, ensure_ascii=False)
        )
        ids = [c["id"] for c in batch]
        api, rec = call_claude(
            SYSTEM,
            [{"role": "user", "content": user}],
            tools=[TOOL],
            max_tokens=16000,
            label=f"tarot-{'-'.join(ids)}",
            effort="low",
        )
        got = {c["id"]: c for c in (tool_input(api, "save_tarot_cards").get("cards") or [])}
        retry = []
        for c in batch:
            rw = got.get(c["id"])
            errs = card_ok(c, rw or {})
            if errs:
                print("  invalid", c["id"], errs[:6])
                retry.append(c)
            else:
                idx = by_id[c["id"]]
                cards[idx]["upright"] = rw["upright"]
                cards[idx]["reversed"] = rw["reversed"]
        if retry and rec["total_usd"] < HARD_STOP_USD:
            api, rec = call_claude(
                SYSTEM,
                [{"role": "user", "content": user + "\nThese need 3–5 sentences per field (except short thread): " + ", ".join(c["id"] for c in retry)}],
                tools=[TOOL],
                max_tokens=16000,
                label=f"tarot-retry-{'-'.join(c['id'] for c in retry)}",
                effort="medium",
            )
            got = {c["id"]: c for c in (tool_input(api, "save_tarot_cards").get("cards") or [])}
            for c in retry:
                rw = got.get(c["id"])
                errs = card_ok(c, rw or {})
                if errs:
                    print("  still invalid", c["id"], errs[:6])
                else:
                    idx = by_id[c["id"]]
                    cards[idx]["upright"] = rw["upright"]
                    cards[idx]["reversed"] = rw["reversed"]
        data["cards"] = cards
        SRC.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
        DEST.write_bytes(SRC.read_bytes())
    leftover = []
    for c in cards:
        leftover.extend(card_ok(c, c) if already_rich(c) is False else [])
        # already_rich True means ok
        leftover.extend([] if already_rich(c) else card_ok(c, c))
    # unique
    leftover = [e for c in cards for e in (card_ok(c, c))]
    Path("/tmp/opus-enrich/tarot_report.txt").write_text(
        "\n".join(leftover or ["none"]) + f"\nspend {spend_record()['total_usd']:.4f}\n"
    )
    print("tarot leftover", len(leftover), "spend", spend_record()["total_usd"])
    return leftover


if __name__ == "__main__":
    leftover = write_tarot()
    sys.exit(1 if leftover else 0)

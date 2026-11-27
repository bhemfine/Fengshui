#!/usr/bin/env python3
"""Build-time Claude enrichment for Inkstone tarot JSON. No user data is sent.

Pricing (Claude API, Sonnet 5.5, Nov 2026): input $2, output $10, 5m cache write $2.50,
cache read $0.10 per million tokens. Stop if estimated spend would exceed $12 (task cap ~$15).
"""
from __future__ import annotations

import json, os, sys, time, urllib.request, urllib.error
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "content" / "tarot"
OUT = ROOT / "content" / "tarot"
SPEND_PATH = Path("/tmp/tarot-enrich/spend.json")
MODEL = "claude-sonnet-5-5"
HARD_STOP_USD = 12.00
# USD per token
PRICE = {
    "input": 2.00 / 1_000_000,
    "output": 10.00 / 1_000_000,
    "cache_write_5m": 2.50 / 1_000_000,
    "cache_write_1h": 4.00 / 1_000_000,
    "cache_read": 0.10 / 1_000_000,
}

SYSTEM = """You are writing original tarot interpretations for Inkstone, a calm Singapore/Malaysia Android app (English with occasional familiar local wording in classifier lists only, not in the readings themselves).

Rules:
- Write original wording. Do not copy Rider–Waite, Crowley, or any published deck text, or the short seed lines verbatim (you may keep their sense).
- Tone: plain, warm, specific, adult. No mysticism for its own sake, no fortune guarantees, no medical/legal/financial advice, no death/illness predictions, no telling anyone to leave a partner, quit a job, or spend money.
- Each field is 1–3 sentences, about 40–240 characters. A 'thread' is a short clause (6–14 words) that can follow 'this card points to'.
- Categories: summary, love, career, money, health (wellbeing/energy, not diagnosis), family (home and family), general, yes_no (prose that leans yes, no, or mixed, matching yes_no_lean), timing (pace and seasons, not a calendar date), advice, thread.
- Upright and reversed must clearly differ. Reversed is a delay, excess, or inner work — not a curse.
- Singapore context is fine when natural (work, family, flat, parents) but do not force local colour.
- Return only a tool call; no preamble.
"""

FIELDS = [
    "summary", "love", "career", "money", "health", "family",
    "general", "yes_no", "timing", "advice", "thread",
]


def spend_record():
    if SPEND_PATH.exists():
        return json.loads(SPEND_PATH.read_text())
    return {"calls": [], "total_usd": 0.0, "input": 0, "output": 0, "cache_read": 0, "cache_write_5m": 0}


def save_spend(rec):
    SPEND_PATH.parent.mkdir(parents=True, exist_ok=True)
    SPEND_PATH.write_text(json.dumps(rec, indent=2))


def cost_of(usage: dict) -> float:
    inp = usage.get("input_tokens") or 0
    out = usage.get("output_tokens") or 0
    # newer shape
    cache_read = usage.get("cache_read_input_tokens") or 0
    creation = usage.get("cache_creation") or {}
    w5 = creation.get("ephemeral_5m_input_tokens")
    w1 = creation.get("ephemeral_1h_input_tokens")
    if w5 is None and w1 is None:
        w5 = usage.get("cache_creation_input_tokens") or 0
        w1 = 0
    w5 = w5 or 0
    w1 = w1 or 0
    usd = (
        inp * PRICE["input"]
        + out * PRICE["output"]
        + (w5 or 0) * PRICE["cache_write_5m"]
        + (w1 or 0) * PRICE["cache_write_1h"]
        + cache_read * PRICE["cache_read"]
    )
    return usd, {"input": inp, "output": out, "cache_read": cache_read, "cache_write_5m": w5, "cache_write_1h": w1}


def call_claude(messages, tools=None, tool_choice=None, max_tokens=16000, label=""):
    rec = spend_record()
    if rec["total_usd"] >= HARD_STOP_USD:
        raise SystemExit(f"Spend cap reached (${rec['total_usd']:.4f}). Stopping before {label}.")
    key = os.environ.get("ANTHROPIC_API_KEY")
    if not key:
        raise SystemExit("ANTHROPIC_API_KEY missing")
    body = {
        "model": MODEL,
        "max_tokens": max_tokens,
        "system": [
            {"type": "text", "text": SYSTEM, "cache_control": {"type": "ephemeral"}}
        ],
        "messages": messages,
    }
    # Prefer low effort / no extra thinking if the API accepts it.
    body["output_config"] = {"effort": "low"}
    if tools:
        body["tools"] = tools
    if tool_choice:
        body["tool_choice"] = tool_choice
    # Sonnet 5.5 rejects tool_choice type "tool" or "any".
    data = json.dumps(body).encode()
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=data,
        headers={
            "x-api-key": key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        method="POST",
    )
    last_err = None
    for attempt in range(5):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                payload = json.loads(r.read().decode())
            break
        except urllib.error.HTTPError as e:
            err = e.read().decode()
            last_err = f"HTTP {e.code} {err[:800]}"
            # If output_config or thinking is rejected, retry once without it.
            if e.code == 400 and "output_config" in err and "output_config" in body:
                print("API rejected output_config; retrying without it", flush=True)
                body.pop("output_config", None)
                data = json.dumps(body).encode()
                req = urllib.request.Request(
                    "https://api.anthropic.com/v1/messages",
                    data=data,
                    headers={
                        "x-api-key": key,
                        "anthropic-version": "2023-06-01",
                        "content-type": "application/json",
                    },
                    method="POST",
                )
                continue
            if e.code in (429, 500, 529, 503):
                time.sleep(5 * (attempt + 1))
                continue
            raise SystemExit(last_err)
        except Exception as e:
            last_err = str(e)
            time.sleep(3 * (attempt + 1))
    else:
        raise SystemExit(f"Failed after retries: {last_err}")

    usage = payload.get("usage") or {}
    usd, parts = cost_of(usage)
    rec["calls"].append({"label": label, "usd": round(usd, 6), "parts": parts, "stop": payload.get("stop_reason")})
    rec["total_usd"] = round(rec["total_usd"] + usd, 6)
    for k, v in parts.items():
        rec[k] = rec.get(k, 0) + (v or 0)
    save_spend(rec)
    print(f"[{label}] ${usd:.4f}  running ${rec['total_usd']:.4f}  tokens {parts}", flush=True)
    if rec["total_usd"] >= HARD_STOP_USD:
        print("Approaching cap; no further calls after this one.", flush=True)
    return payload, rec


def load_cards():
    cards = []
    for fn in ("major_arcana.json", "wands_cups.json", "swords_pentacles.json"):
        d = json.loads((SRC / fn).read_text())
        cards.extend(d["cards"])
    if len(cards) != 78:
        raise SystemExit(f"expected 78 cards, got {len(cards)}")
    return cards


def seed_for(c):
    return {
        "id": c["id"],
        "name": c["name"],
        "arcana": c["arcana"],
        "suit": c["suit"],
        "number": c["number"],
        "element": c.get("element"),
        "keywords_upright": c.get("keywords_upright"),
        "keywords_reversed": c.get("keywords_reversed"),
        "yes_no_lean": c.get("yes_no"),
        "seed_upright": c.get("upright"),
        "seed_reversed": c.get("reversed"),
    }


ORIENT_PROPS = {k: {"type": "string"} for k in FIELDS}
CARD_ITEM = {
    "type": "object",
    "additionalProperties": False,
    "required": ["id", "upright", "reversed"],
    "properties": {
        "id": {"type": "string"},
        "upright": {"type": "object", "additionalProperties": False, "required": FIELDS, "properties": ORIENT_PROPS},
        "reversed": {"type": "object", "additionalProperties": False, "required": FIELDS, "properties": ORIENT_PROPS},
    },
}

SUBMIT_CARDS_TOOL = {
    "name": "submit_card_batch",
    "description": "Submit enriched interpretations for this batch of cards.",
    "input_schema": {
        "type": "object",
        "additionalProperties": False,
        "required": ["cards"],
        "properties": {
            "cards": {"type": "array", "items": CARD_ITEM},
        },
    },
}


def _coerce_cards(result):
    cards = result.get("cards") if isinstance(result, dict) else result
    if isinstance(cards, str):
        cards = json.loads(cards)
    if isinstance(cards, dict) and "cards" in cards:
        cards = cards["cards"]
    if isinstance(cards, dict):
        # id -> body
        cards = [{"id": k, **(v if isinstance(v, dict) else {"raw": v})} for k, v in cards.items()]
    if not isinstance(cards, list):
        raise SystemExit(f"cards is {type(cards)}: {str(cards)[:400]}")
    out = []
    for i, c in enumerate(cards):
        if isinstance(c, str):
            try:
                c = json.loads(c)
            except Exception:
                raise SystemExit(f"card[{i}] is a string: {c[:200]}")
        if not isinstance(c, dict):
            raise SystemExit(f"card[{i}] is {type(c)}")
        out.append(c)
    return {"cards": out}

def extract_tool(payload, name):
    for block in payload.get("content") or []:
        if block.get("type") == "tool_use" and block.get("name") == name:
            raw = block.get("input") or {}
            # Always keep a copy for debugging malformed batches.
            Path("/tmp/tarot-enrich/last_tool.json").write_text(json.dumps(raw, ensure_ascii=False)[:2_000_000])
            if name == "submit_card_batch":
                return _coerce_cards(raw)
            return raw
    texts = [b.get("text") for b in payload.get("content") or [] if b.get("type") == "text"]
    raise SystemExit(f"No tool_use {name}. blocks={[b.get('type') for b in payload.get('content') or []]} text={(texts[:1] or [''])[0][:400]}")


def validate_batch(seeds, result):
    got = {c["id"]: c for c in result["cards"]}
    missing = [s["id"] for s in seeds if s["id"] not in got]
    if missing:
        raise SystemExit(f"Missing cards: {missing}")
    if len(result["cards"]) != len(seeds):
        # allow extras? no
        extra = [c["id"] for c in result["cards"] if c["id"] not in {s["id"] for s in seeds}]
        raise SystemExit(f"Count mismatch extras={extra}")
    for c in result["cards"]:
        for orient in ("upright", "reversed"):
            for f in FIELDS:
                t = (c[orient].get(f) or "").strip()
                if len(t) < 8:
                    raise SystemExit(f"{c['id']} {orient}.{f} too short: {t!r}")
    return True


def merge_card(orig, enriched):
    out = {
        "id": orig["id"],
        "name": orig["name"],
        "arcana": orig["arcana"],
        "suit": orig["suit"],
        "number": orig["number"],
        "element": orig.get("element"),
        "keywords_upright": orig.get("keywords_upright"),
        "keywords_reversed": orig.get("keywords_reversed"),
        "yes_no_lean": orig.get("yes_no"),
        "image_prompt": orig.get("image_prompt"),
        "upright": enriched["upright"],
        "reversed": enriched["reversed"],
    }
    return out


def enrich_cards(batch_size=6, start=0, only=None):
    cards = load_cards()
    if only:
        cards = [c for c in cards if c["id"] in only]
    work = cards[start:]
    out_path = OUT / "readings.json"
    existing = []
    done_ids = set()
    if out_path.exists():
        prev = json.loads(out_path.read_text())
        existing = prev.get("cards") or []
        done_ids = {c["id"] for c in existing}
    pending = [c for c in work if c["id"] not in done_ids]
    print(f"Already have {len(done_ids)}; pending {len(pending)}", flush=True)
    while pending:
        rec = spend_record()
        if rec["total_usd"] >= HARD_STOP_USD:
            print("Stop: spend cap.")
            break
        batch = pending[:batch_size]
        pending = pending[batch_size:]
        seeds = [seed_for(c) for c in batch]
        user = (
            "Enrich these tarot cards. Keep each id unchanged. "
            "Fill every field for upright and reversed.\n\n"
            + json.dumps(seeds, ensure_ascii=False)
        )
        payload, rec = call_claude(
            [{"role": "user", "content": user}],
            tools=[SUBMIT_CARDS_TOOL],
            tool_choice={"type": "auto"},
            label=f"cards:{','.join(c['id'] for c in batch)}",
        )
        result = extract_tool(payload, "submit_card_batch")
        validate_batch(seeds, result)
        by_id = {c["id"]: c for c in result["cards"]}
        for orig in batch:
            existing.append(merge_card(orig, by_id[orig["id"]]))
        write_readings(existing)
        print(f"Wrote {len(existing)} / 78 cards", flush=True)
    return existing


def write_readings(cards):
    # Keep original order
    order = [c["id"] for c in load_cards()]
    by = {c["id"]: c for c in cards}
    ordered = [by[i] for i in order if i in by]
    doc = {
        "version": 2,
        "locale": "en-SG",
        "disclaimer": "For reflection and entertainment only. Not medical, legal, financial or professional advice.",
        "source": "Build-time draft (Claude Sonnet 5.5). Review before launch. User questions are never sent to this model.",
        "categories": [
            "summary", "love", "career", "money", "health", "family",
            "general", "yes_no", "timing", "advice",
        ],
        "cards": ordered,
    }
    (OUT / "readings.json").write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n")


SUBMIT_SUPPORT_TOOL = {
    "name": "submit_support_pack",
    "description": "Classifier phrases and spread connective text.",
    "input_schema": {
        "type": "object",
        "additionalProperties": False,
        "required": ["classifier", "spreads"],
        "properties": {
            "classifier": {"type": "object"},
            "spreads": {"type": "object"},
        },
    },
}

SUPPORT_PROMPT = """Produce two JSON objects for an on-device tarot reader. No user question will be sent to you in production; this is only the phrase list and connective templates.

1) classifier
Categories for the TOPIC of a question: love, career, money, health, family, general.
Separate flags (not topics): yes_no, timing.
For each topic and flag, give:
- phrases: 25–60 multi-word phrases (lowercase) that strongly indicate it. Include everyday English, plus common Singapore English / Singlish, and common Chinese romanisation (pinyin, and a few frequent romanised terms such as yuan fen, gong zuo, cai yun, jian kang, jia ting, lian ai, ai qing, shi ye, sheng yi, fang zi, ba gua only if natural).
- keywords: 20–40 single tokens (lowercase, no punctuation).
Do not include offensive slurs. Prefer recall for genuine questions; avoid very generic words like 'life' or 'me' as keywords.
Also include:
- ignore: a short list of stopwords that must not swing the score (the, a, to, should, i, my, ...).
Structure:
{
  "topics": { "love": {"phrases":[], "keywords":[]}, ... "general": {"phrases":[], "keywords":[]} },
  "flags": { "yes_no": {"phrases":[], "keywords":[]}, "timing": {"phrases":[], "keywords":[]} },
  "ignore": []
}
yes_no phrases like: "should i", "will he", "will she", "is it a yes", "or not", "confirm or not", "can or not", "steady or not".
timing phrases like: "when will", "how soon", "right time", "this year", "this month", "wait or move".

2) spreads
{
  "spreads": [
    {
      "id": "single",
      "name": "One card",
      "blurb": "A single card for this question.",
      "positions": [
        {"id": "focus", "label": "This card", "intro": "A short sentence introducing a one-card answer."}
      ]
    },
    {
      "id": "past_present_future",
      "name": "Past, present, future",
      "blurb": "...",
      "positions": [
        {"id": "past", "label": "Past", "intro": "..."},
        {"id": "present", "label": "Present", "intro": "..."},
        {"id": "future", "label": "Future", "intro": "..."}
      ]
    },
    {
      "id": "situation_action_outcome",
      "name": "Situation, action, outcome",
      "blurb": "...",
      "positions": [
        {"id": "situation", "label": "Situation", "intro": "..."},
        {"id": "action", "label": "Action", "intro": "..."},
        {"id": "outcome", "label": "Outcome", "intro": "..."}
      ]
    }
  ],
  "openers": {
    "love": "One sentence shown before the cards when the question is about love.",
    "career": "...",
    "money": "...",
    "health": "...",
    "family": "...",
    "general": "One sentence when there is no clear topic or no question."
  },
  "closings": {
    "single": "One short closing sentence after a one-card reading.",
    "all_upright": "Closing when every card is upright (3-card).",
    "mixed": "Closing when the spread is mixed.",
    "all_reversed": "Closing when every card is reversed."
  },
  "yes_no_bridge": "A short lead-in before the yes/no lean, e.g. 'On the yes-or-no side of the question:'",
  "timing_bridge": "A short lead-in before the timing text."
}

Write original, calm copy. No guarantees.
"""


def enrich_support():
    payload, rec = call_claude(
        [{"role": "user", "content": SUPPORT_PROMPT}],
        tools=[SUBMIT_SUPPORT_TOOL],
        tool_choice={"type": "auto"},
        max_tokens=20000,
        label="support:classifier+spreads",
    )
    result = extract_tool(payload, "submit_support_pack")
    clf = result["classifier"]
    spr = result["spreads"]
    # light validation
    for t in ("love", "career", "money", "health", "family", "general"):
        if t not in clf.get("topics", {}):
            raise SystemExit(f"classifier missing topic {t}")
        ph = clf["topics"][t].get("phrases") or []
        if len(ph) < 10:
            raise SystemExit(f"too few phrases for {t}: {len(ph)}")
    (OUT / "classifier.json").write_text(json.dumps({
        "version": 1,
        "locale": "en-SG",
        "disclaimer": "On-device only. Questions never leave the phone.",
        **clf,
    }, ensure_ascii=False, indent=2) + "\n")
    (OUT / "spreads.json").write_text(json.dumps({
        "version": 1,
        "locale": "en-SG",
        **spr,
    }, ensure_ascii=False, indent=2) + "\n")
    print("Wrote classifier.json and spreads.json", flush=True)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "all"
    if cmd == "support":
        enrich_support()
    elif cmd == "cards":
        enrich_cards()
    elif cmd == "all":
        if not (OUT / "classifier.json").exists() or not (OUT / "spreads.json").exists():
            enrich_support()
        enrich_cards()
    elif cmd == "spend":
        print(json.dumps(spend_record(), indent=2))
    else:
        raise SystemExit("usage: enrich_tarot.py [all|cards|support|spend]")

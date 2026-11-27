#!/usr/bin/env python3
"""Build-time Opus 5.5 writer for Inkstone Your Year packs and richer tarot.

No user data is sent. Stop if estimated spend would exceed HARD_STOP_USD.
Pricing (Nov 2026, Opus 5.5): input $4, output $20, 5m cache write $5, cache read $0.20 per MTok.
"""
from __future__ import annotations

import json, os, sys, time, urllib.request, urllib.error, copy, re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEND_PATH = Path("/tmp/opus-enrich/spend.json")
MODEL = "claude-opus-5-5"
HARD_STOP_USD = 38.00
PRICE = {
    "input": 4.00 / 1_000_000,
    "output": 20.00 / 1_000_000,
    "cache_write_5m": 5.00 / 1_000_000,
    "cache_write_1h": 10.00 / 1_000_000,
    "cache_read": 0.20 / 1_000_000,
}

YEARS = {
    2028: {"zh": "戊申", "pinyin": "wù shēn", "en": "Earth Monkey year"},
    2029: {"zh": "己酉", "pinyin": "jǐ yǒu", "en": "Earth Rooster year"},
    2030: {"zh": "庚戌", "pinyin": "gēng xū", "en": "Metal Dog year"},
    2031: {"zh": "辛亥", "pinyin": "xīn hài", "en": "Metal Pig year"},
    2032: {"zh": "壬子", "pinyin": "rén zǐ", "en": "Water Rat year"},
    2033: {"zh": "癸丑", "pinyin": "guǐ chǒu", "en": "Water Ox year"},
    2034: {"zh": "甲寅", "pinyin": "jiǎ yín", "en": "Wood Tiger year"},
    2035: {"zh": "乙卯", "pinyin": "yǐ mǎo", "en": "Wood Rabbit year"},
}
ANIMALS = ["rat", "ox", "tiger", "rabbit", "dragon", "snake", "horse", "goat", "monkey", "rooster", "dog", "pig"]
YEAR_FIELDS = ["overview", "career", "money", "love", "health_wellbeing", "dos", "avoids", "lucky_months", "tai_sui_note"]

TAROT_FIELDS = [
    "summary", "love", "career", "money", "health", "family",
    "general", "yes_no", "timing", "advice", "thread",
]


def spend_record():
    if SPEND_PATH.exists():
        return json.loads(SPEND_PATH.read_text())
    return {"calls": [], "total_usd": 0.0, "input": 0, "output": 0, "cache_read": 0, "cache_write_5m": 0, "cache_write_1h": 0}


def save_spend(rec):
    SPEND_PATH.parent.mkdir(parents=True, exist_ok=True)
    SPEND_PATH.write_text(json.dumps(rec, indent=2))


def cost_of(usage: dict) -> tuple[float, dict]:
    inp = usage.get("input_tokens") or 0
    out = usage.get("output_tokens") or 0
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
        + w5 * PRICE["cache_write_5m"]
        + w1 * PRICE["cache_write_1h"]
        + cache_read * PRICE["cache_read"]
    )
    return usd, {"input": inp, "output": out, "cache_read": cache_read, "cache_write_5m": w5, "cache_write_1h": w1}


def call_claude(system, messages, tools=None, max_tokens=16000, label="", effort="low"):
    rec = spend_record()
    if rec["total_usd"] >= HARD_STOP_USD:
        raise SystemExit(f"Hard stop before call {label}: ${rec['total_usd']:.4f}")
    key = os.environ.get("ANTHROPIC_API_KEY")
    if not key:
        raise SystemExit("ANTHROPIC_API_KEY is not set")
    body = {
        "model": MODEL,
        "max_tokens": max_tokens,
        "system": [
            {
                "type": "text",
                "text": system,
                "cache_control": {"type": "ephemeral"},
            }
        ],
        "messages": messages,
        "output_config": {"effort": effort},
    }
    if tools:
        body["tools"] = tools
        body["tool_choice"] = {"type": "auto"}
    req = urllib.request.Request(
        "https://api.anthropic.com/v1/messages",
        data=json.dumps(body).encode(),
        headers={
            "content-type": "application/json",
            "x-api-key": key,
            "anthropic-version": "2023-06-01",
        },
        method="POST",
    )
    last_err = None
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                data = json.loads(r.read().decode())
            last_err = None
            break
        except urllib.error.HTTPError as e:
            err = e.read().decode()[:2000]
            raise SystemExit(f"HTTP {e.code} on {label}: {err}") from e
        except (TimeoutError, urllib.error.URLError) as e:
            last_err = e
            print(f"  timeout/retry {attempt+1} on {label}: {e}", flush=True)
            time.sleep(4 * (attempt + 1))
    if last_err is not None:
        raise SystemExit(f"Giving up on {label}: {last_err}")
    usage = data.get("usage") or {}
    usd, toks = cost_of(usage)
    rec["total_usd"] = rec.get("total_usd", 0) + usd
    for k, v in toks.items():
        rec[k] = rec.get(k, 0) + v
    rec["calls"].append({"label": label, "usd": round(usd, 6), **toks, "stop": data.get("stop_reason")})
    save_spend(rec)
    print(f"  {label}: ${usd:.4f}  running ${rec['total_usd']:.4f}", flush=True)
    if rec["total_usd"] >= HARD_STOP_USD:
        print("Hard stop after call", label)
    return data, rec


def tool_input(data, name):
    for b in data.get("content") or []:
        if b.get("type") == "tool_use" and b.get("name") == name:
            return b.get("input") or {}
    # sometimes the model returns JSON in text
    for b in data.get("content") or []:
        if b.get("type") == "text" and b.get("text"):
            try:
                return json.loads(b["text"])
            except Exception:
                pass
    raise RuntimeError(f"no tool {name} in response: {json.dumps(data)[:500]}")


YEAR_SYSTEM = """You write original yearly horoscope text for Inkstone, a calm Singapore/Malaysia Android app.

Rules:
- English only. Plain, warm, specific, adult. No fortune guarantees, no medical/legal/financial advice, no death or illness predictions, no telling anyone to quit, leave a partner, or spend money.
- Do not copy published almanacs. Write original sentences.
- Each of overview, career, money, love, health_wellbeing must be 3–5 sentences (about 280–700 characters). Be detailed and practical.
- dos and avoids: 4–6 short imperative phrases each, not sentences.
- lucky_months: 2–4 of: rat, ox, tiger, rabbit, dragon, snake, horse, goat, monkey, rooster, dog, pig (month animals).
- tai_sui_note: 2–4 sentences about that animal's relation to the year's Tai Sui (own year, clash, punishment, harm, break, six harmony, three harmony, or none). Use the relation you are given. Mention folk custom without commanding a temple visit.
- Singapore life (work, family, HDB/condo) is fine when natural.
- Return only a tool call.
"""

YEAR_TOOL = {
    "name": "save_year_animals",
    "description": "Save yearly guides for several animals of one solar year.",
    "input_schema": {
        "type": "object",
        "required": ["year", "animals"],
        "properties": {
            "year": {"type": "integer"},
            "animals": {
                "type": "object",
                "additionalProperties": {
                    "type": "object",
                    "required": YEAR_FIELDS,
                    "properties": {
                        "overview": {"type": "string"},
                        "career": {"type": "string"},
                        "money": {"type": "string"},
                        "love": {"type": "string"},
                        "health_wellbeing": {"type": "string"},
                        "dos": {"type": "array", "items": {"type": "string"}},
                        "avoids": {"type": "array", "items": {"type": "string"}},
                        "lucky_months": {"type": "array", "items": {"type": "string"}},
                        "tai_sui_note": {"type": "string"},
                    },
                },
            },
        },
    },
}

PLACEHOLDER_RE = re.compile(r"\b(TODO|TBD|lorem|placeholder|xxx)\b", re.I)


def valid_animal(block: dict, animal: str) -> list[str]:
    errs = []
    if not isinstance(block, dict):
        return [f"{animal} not an object"]
    for f in ["overview", "career", "money", "love", "health_wellbeing", "tai_sui_note"]:
        v = block.get(f)
        if not isinstance(v, str) or not v.strip():
            errs.append(f"{animal}.{f} empty")
        elif len(v.strip()) < 80:
            errs.append(f"{animal}.{f} too short ({len(v.strip())})")
        elif PLACEHOLDER_RE.search(v):
            errs.append(f"{animal}.{f} placeholder")
    for f in ["dos", "avoids"]:
        v = block.get(f)
        if not isinstance(v, list) or len(v) < 4 or any(not str(x).strip() for x in v):
            errs.append(f"{animal}.{f} need 4+ non-empty items")
    months = block.get("lucky_months") or []
    if not isinstance(months, list) or len(months) < 2:
        errs.append(f"{animal}.lucky_months need 2+")
    else:
        for m in months:
            if str(m).lower() not in ANIMALS:
                errs.append(f"{animal}.lucky_months bad {m}")
    return errs


def write_years():
    path = ROOT / "content" / "forecast_templates.json"
    data = json.loads(path.read_text())
    yearly = data.setdefault("yearly", {})
    # 4 animals per call, 8 years × 3 calls
    batches = [ANIMALS[i:i+4] for i in range(0, 12, 4)]
    for year, meta in YEARS.items():
        ykey = str(year)
        block = yearly.get(ykey) or {}
        block.update(meta)
        animals_out = dict(block.get("animals") or {})
        for batch in batches:
            missing = [a for a in batch if valid_animal(animals_out.get(a) or {}, a)]
            if not missing:
                print(f"  {year} {batch} already ok")
                continue
            rec = spend_record()
            if rec["total_usd"] >= HARD_STOP_USD:
                print("stop years")
                break
            rel = (
                "Use well-known Tai Sui relations: own year (ben ming) when the animal matches the year animal; "
                "clash opposite (six away); self-punishment and classic punishments; six harmony and three harmony where they apply; "
                "otherwise a calm 'no direct clash or harmony' note."
            )
            user = (
                f"Write detailed {year} ({meta['zh']} {meta['en']}) guides for these animals only: {', '.join(missing)}.\n"
                f"{rel}\n"
                "Keys must be lowercase animal names."
            )
            data_api, rec = call_claude(
                YEAR_SYSTEM,
                [{"role": "user", "content": user}],
                tools=[YEAR_TOOL],
                max_tokens=16000,
                label=f"year-{year}-{'-'.join(missing)}",
                effort="low",
            )
            inp = tool_input(data_api, "save_year_animals")
            got = inp.get("animals") or {}
            # coerce keys
            got = {str(k).lower(): v for k, v in got.items()}
            retry = []
            for a in missing:
                errs = valid_animal(got.get(a) or {}, a)
                if errs:
                    print("   invalid", a, errs)
                    retry.append(a)
                else:
                    animals_out[a] = got[a]
            if retry and rec["total_usd"] < HARD_STOP_USD:
                data_api, rec = call_claude(
                    YEAR_SYSTEM,
                    [{"role": "user", "content": user + "\nFix these animals, longer and complete: " + ", ".join(retry)}],
                    tools=[YEAR_TOOL],
                    max_tokens=16000,
                    label=f"year-{year}-retry-{'-'.join(retry)}",
                    effort="medium",
                )
                got = {str(k).lower(): v for k, v in (tool_input(data_api, "save_year_animals").get("animals") or {}).items()}
                for a in retry:
                    errs = valid_animal(got.get(a) or {}, a)
                    if errs:
                        print("   still invalid", a, errs)
                    else:
                        animals_out[a] = got[a]
            block["animals"] = animals_out
            yearly[ykey] = block
            data["yearly"] = yearly
            path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n")
            # copy to app assets
            dest = ROOT / "flutter_app" / "assets" / "content" / "forecast_templates.json"
            dest.write_bytes(path.read_bytes())
        else:
            continue
        break
    # final check
    missing = []
    for year in YEARS:
        for a in ANIMALS:
            errs = valid_animal((yearly.get(str(year)) or {}).get("animals", {}).get(a) or {}, a)
            if errs:
                missing.extend(errs)
    report = ROOT / "content" / "YOUR_YEAR_OPUS_REPORT.txt"
    report.write_text("missing or short:\n" + "\n".join(missing or ["none"]) + f"\nspend {spend_record()['total_usd']:.4f}\n")
    print("years done, issues", len(missing), "spend", spend_record()["total_usd"])
    return missing


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else "years"
    if mode == "years":
        missing = write_years()
        sys.exit(1 if missing else 0)
    else:
        raise SystemExit(f"unknown mode {mode}")


if __name__ == "__main__":
    main()

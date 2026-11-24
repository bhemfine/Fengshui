# Inkstone AI prompts

This folder holds the system prompts and output schemas used by the stateless proxy in `proxy/worker`. Each task has two files:

- `<task>.system.md`: the system prompt, bundled into the Worker as a text module.
- `<task>.schema.json`: a strict JSON Schema (draft 2020-12, `additionalProperties: false` on every object). The Worker sends the schema to the model and checks the reply against it before returning it.

## How the app calls each endpoint

All AI calls use one route:

```
POST /v1/ai/{task}
Headers:
  Content-Type: application/json
  X-Install-Id: <random UUID v4 generated once per install, stored only on the phone>
  X-Integrity-Token: <Play Integrity token>
Body:
  {
    "input":  { ...task-specific JSON... },
    "images": [ { "media_type": "image/jpeg", "data": "<base64>" } ]   // only for vision tasks
  }
```

The response is the task JSON (matching the schema) with `Cache-Control: no-store`.

| Task | Images | `input` sent by the app (no names, no addresses, no raw birth data) | Output budget (`max_tokens`) |
| --- | --- | --- | --- |
| `floor_plan_reading` | 1 floor plan (required) | `facing_degrees`, `period`, `occupant_kua_numbers[]`, optional `engine_flying_stars` (per-palace stars computed on device), optional `user_marked_rooms[]` | 3000 |
| `palm_reading` | 1 palm photo (required) | `hand` (`left`/`right`/`unknown`), `dominant` (bool), optional `rule_table_hints[]` | 2000 |
| `house_check` | 1 to 4 Street View or satellite images | `facing_degrees`, `surroundings_tags[]` (e.g. `t_junction_candidate`, `hospital_within_300m`), optional `headings[]` | 2000 |
| `daily_writeup` | none | `chart_factors`, `day_factors`, `score`, `tags[]`, `snippets[]` (all from the on-device engine and bundled content) | 900 |
| `monthly_writeup` | none | same shape, month factors | 1500 |
| `yearly_writeup` | none | same shape, year factors plus optional `home_flying_stars` | 2200 |
| `compatibility` | none | `relationship_type`, `chart_a`, `chart_b` (factors only), `scores[]` per method, `overall_score`, `tags[]` | 1600 |
| `ask_the_master` | none | `question`, `retrieved_passages[]` (from the on-device knowledge base), `context` (chart factors, home findings, today's almanac) | 1500 |

Maps routes (same headers, no body):

- `GET /v1/maps/streetview?lat=..&lng=..&heading=..&fov=..&pitch=..` returns a JPEG.
- `GET /v1/maps/geocode-free?lat=..&lng=..` returns Street View metadata only (imagery available, capture date). It never returns or looks up an address.

Coordinates are rounded to 4 decimal places (about 11 m) before they reach Google.

## Model choice

The Worker calls Anthropic Claude through the Messages API. A vision-capable Claude model is required for the three image tasks; the default is set in `wrangler.toml` (`ANTHROPIC_MODEL`) and can be changed without an app release. The API key lives only in the Worker secret `ANTHROPIC_API_KEY`. The app never holds an AI or Maps key.

## Token budgets

Output budgets are in the table above and in `proxy/worker/src/prompts.ts`. Input is capped by the Worker (request body max 8 MB, max 4 images, each image max about 5 MB base64). Keep `snippets` and `retrieved_passages` short on the device side (suggested: under 4,000 characters total) to keep cost predictable.

## Caching off

- No Anthropic prompt caching (`cache_control` is never sent).
- No Cloudflare cache: every response carries `Cache-Control: no-store`.
- No KV, D1, R2 or Durable Objects. The app caches results locally on the phone.

## Rules every prompt follows

- Plain English; Chinese terms as Hanzi + pinyin + English, e.g. 飞星 (fēi xīng, Flying Stars).
- Entertainment and guidance disclaimer in every output.
- No fear-selling, no pressure to buy talismans or cures, never claim certainty.
- Never ask for or repeat names, addresses or identifiers.
- The model never recomputes charts. It phrases engine output only.
- JSON only, matching the schema.

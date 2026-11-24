# Smoke tests

Run locally with integrity checks off:

```
npm install
npx wrangler dev --var INTEGRITY_MODE:off
```

Set helpers:

```
BASE=http://localhost:8787
IID=$(uuidgen | tr 'A-Z' 'a-z')   # must be a v4 UUID
H=(-H "X-Install-Id: $IID" -H "X-Integrity-Token: dev-placeholder-token")
```

## Health

```
curl -i $BASE/healthz
```
Expect `200`, `Cache-Control: no-store...`.

## Daily write-up (text only)

```
curl -s "${H[@]}" -H "Content-Type: application/json" -X POST $BASE/v1/ai/daily_writeup -d '{
  "input": {
    "chart_factors": {"day_master": "Yang Wood (Jia)", "favourable_elements": ["Water","Wood"]},
    "day_factors": {"day_pillar": "Ren Zi", "officer": "Establish", "mansion": "Horn", "clashes": [], "combinations": ["Zi-Chou"]},
    "lucky": {"colour": "deep blue", "direction": "North", "hours": ["23:00-01:00","07:00-09:00"]},
    "score": 74,
    "tags": ["supportive_water_day"],
    "snippets": ["Establish days favour starting plans."]
  }
}'
```
Expect JSON with `headline`, `good_to_do`, `rule_citations`, `disclaimer`.

## Identifier rejection

```
curl -s "${H[@]}" -H "Content-Type: application/json" -X POST $BASE/v1/ai/daily_writeup \
  -d '{"input":{"name":"Tan","score":50}}'
```
Expect `400 {"error":"identifiers_not_allowed"}`.

## Palm reading (image)

```
IMG=$(base64 -w0 palm.jpg)
curl -s "${H[@]}" -H "Content-Type: application/json" -X POST $BASE/v1/ai/palm_reading \
  -d "{\"input\":{\"hand\":\"right\",\"dominant\":true},\"images\":[{\"media_type\":\"image/jpeg\",\"data\":\"$IMG\"}]}"
```
Try with a selfie: expect `status: "refused"`, `refusal_reason: "face_or_person"`.

## Floor plan

```
IMG=$(base64 -w0 plan.jpg)
curl -s "${H[@]}" -H "Content-Type: application/json" -X POST $BASE/v1/ai/floor_plan_reading \
  -d "{\"input\":{\"facing_degrees\":135,\"period\":9,\"occupant_kua_numbers\":[1,6]},\"images\":[{\"media_type\":\"image/jpeg\",\"data\":\"$IMG\"}]}"
```
Without `engine_flying_stars`, every `stars_from_input` must be `null`.

## Ask the Master

```
curl -s "${H[@]}" -H "Content-Type: application/json" -X POST $BASE/v1/ai/ask_the_master -d '{
  "input": {"question": "Where should I put a fish tank?",
            "retrieved_passages": [{"source":"Bundled rule set FS-12","text":"Water features suit the annual wealth sector."}],
            "context": {"annual_wealth_sector":"N"}}
}'
```

## Street View

```
curl -s "${H[@]}" -o view.jpg "$BASE/v1/maps/streetview?lat=1.352083&lng=103.819836&heading=90"
curl -s "${H[@]}" "$BASE/v1/maps/geocode-free?lat=1.352083&lng=103.819836"
```
Coordinates are rounded to `1.3521,103.8198` before Google is called.

## Rate limit

Loop 25 calls to `/v1/ai/daily_writeup` with the same install id; expect `429` after 20 within a minute.

## Missing integrity (production mode)

Deploy to staging with `INTEGRITY_MODE=enforce` and omit `X-Integrity-Token`: expect `401`.

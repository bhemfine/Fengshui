# Inkstone stateless proxy (Cloudflare Worker)

A tiny Worker that hides the Anthropic and Google Maps keys, rate-limits per anonymous install, and forwards requests. It has no database and stores nothing.

## Routes

| Method | Path | Purpose |
| --- | --- | --- |
| POST | `/v1/ai/{task}` | `floor_plan_reading`, `palm_reading`, `house_check`, `daily_writeup`, `monthly_writeup`, `yearly_writeup`, `compatibility`, `ask_the_master` |
| GET | `/v1/maps/streetview` | Static Street View JPEG (`lat`, `lng`, `heading`, `fov`, `pitch`) |
| GET | `/v1/maps/geocode-free` | Street View metadata only; never returns an address |
| GET | `/healthz` | Liveness |

Required headers: `X-Install-Id` (random v4 UUID made on the phone) and `X-Integrity-Token` (Play Integrity). See `../prompts/README.md` for request bodies and `test/smoke.md` for curl examples.

## Deploy

```
cd proxy/worker
npm install
npx wrangler login
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put GOOGLE_MAPS_KEY
npm run typecheck
npx wrangler deploy            # add --env staging / production once environments are defined
```

Then:

1. In the Cloudflare dashboard, confirm Workers Logs / Observability, Logpush and Tail consumers are off for this Worker.
2. Restrict the Google Maps key to the Street View Static API only, with a daily quota.
3. Set a monthly spend limit on the Anthropic key.
4. Replace the Play Integrity placeholder in `verifyIntegrity` with a real decode call before public launch.

For local development: `npm run dev` (sets `INTEGRITY_MODE=off`).

## What this server never stores

- No request bodies, prompts, images, floor plans, palm photos, Street View images or AI results. No KV, D1, R2, Durable Objects or Queues are bound.
- No coordinates or addresses. Coordinates are rounded to 4 decimal places and only forwarded to Google; there is no address lookup at all.
- No names, birth details or identifiers. Inputs containing keys such as `name`, `address`, `email`, `birth_date` are rejected.
- No IP addresses. Outgoing requests are built with fresh headers, so `CF-Connecting-IP`, `X-Forwarded-For` and similar are never forwarded to Anthropic or Google.
- No install ids. The id is hashed and passed to the Cloudflare Rate Limiting binding, which keeps a counter only for its window (60 s).
- No logs. There is no `console.log` of bodies or identifiers, `logpush = false`, and observability is disabled in `wrangler.toml`.
- No cache. Every response sends `Cache-Control: no-store`; Anthropic prompt caching is not used.
- No accounts and no purchase history. Integrity tokens are checked and discarded.

Third parties (Anthropic, Google) process the forwarded content under their own API terms; review their data-retention settings and reflect them in the app's privacy policy.

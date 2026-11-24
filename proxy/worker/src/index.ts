// Inkstone stateless proxy.
// Rules: no storage bindings, no console.log of bodies or identifiers, no IP forwarding,
// Cache-Control: no-store on every response.

import { TASKS, isTaskName, type TaskDef } from "./prompts";
import { validate } from "./validate";

interface RateLimiterBinding {
  limit(options: { key: string }): Promise<{ success: boolean }>;
}

export interface Env {
  ANTHROPIC_API_KEY: string;
  GOOGLE_MAPS_KEY: string;
  ANTHROPIC_MODEL?: string;
  INTEGRITY_MODE?: string;
  AI_LIMITER: RateLimiterBinding;
  MAPS_LIMITER: RateLimiterBinding;
}

const MAX_BODY_BYTES = 8 * 1024 * 1024;
const MAX_IMAGE_B64 = 5 * 1024 * 1024;
const ALLOWED_MEDIA = new Set(["image/jpeg", "image/png", "image/webp"]);
const FORBIDDEN_KEYS = new Set([
  "name", "full_name", "first_name", "last_name", "display_name", "address", "street",
  "postal_code", "postcode", "email", "phone", "nric", "birth_date", "birthdate", "dob",
  "birth_time", "birthplace", "device_id", "user_id",
]);
const UUID_V4 = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

const BASE_HEADERS: Record<string, string> = {
  "Cache-Control": "no-store, no-cache, must-revalidate, private",
  Pragma: "no-cache",
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
};

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...BASE_HEADERS, "Content-Type": "application/json; charset=utf-8" },
  });
}

function fail(status: number, code: string): Response {
  return json(status, { error: code });
}

async function sha256Hex(text: string): Promise<string> {
  const buf = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// Placeholder: real implementation decodes the token with Google's Play Integrity API
// (service account held as a Worker secret) and checks package name, app integrity and
// a request-bound nonce. Nothing from the token is stored.
async function verifyIntegrity(token: string | null, env: Env): Promise<boolean> {
  if (env.INTEGRITY_MODE === "off") return true;
  if (!token) return false;
  return /^[A-Za-z0-9_\-.=]{16,8192}$/.test(token);
}

// Checks integrity + install id, then rate-limits on a hash of the install id.
// The limiter keeps counters only for its window; we never persist the id.
async function gate(request: Request, env: Env, limiter: RateLimiterBinding, bucket: string): Promise<Response | null> {
  const installId = request.headers.get("X-Install-Id");
  if (!installId || !UUID_V4.test(installId)) return fail(400, "invalid_install_id");
  if (!(await verifyIntegrity(request.headers.get("X-Integrity-Token"), env))) return fail(401, "integrity_failed");
  const key = await sha256Hex(`${bucket}:${installId.toLowerCase()}`);
  const { success } = await limiter.limit({ key });
  if (!success) return fail(429, "rate_limited");
  return null;
}

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return typeof v === "object" && v !== null && !Array.isArray(v);
}

function containsForbiddenKey(v: unknown, depth = 0): boolean {
  if (depth > 12) return true;
  if (Array.isArray(v)) return v.some((x) => containsForbiddenKey(x, depth + 1));
  if (isPlainObject(v)) {
    for (const [k, val] of Object.entries(v)) {
      if (FORBIDDEN_KEYS.has(k.toLowerCase())) return true;
      if (containsForbiddenKey(val, depth + 1)) return true;
    }
  }
  return false;
}

interface ImageIn {
  media_type: string;
  data: string;
}

type ContentBlock =
  | { type: "image"; source: { type: "base64"; media_type: string; data: string } }
  | { type: "text"; text: string };

interface AnthropicResponse {
  content?: Array<{ type: string; text?: string }>;
}

function extractJson(text: string): unknown {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) throw new Error("no_json");
  return JSON.parse(text.slice(start, end + 1));
}

async function callModel(env: Env, task: TaskDef, input: Record<string, unknown>, images: ImageIn[]): Promise<unknown | null> {
  const system = `${task.system}\n\nOUTPUT JSON SCHEMA (follow exactly):\n${JSON.stringify(task.schema)}`;
  for (let attempt = 0; attempt < 2; attempt++) {
    const content: ContentBlock[] = images.map((img) => ({
      type: "image" as const,
      source: { type: "base64" as const, media_type: img.media_type, data: img.data },
    }));
    let text = `INPUT JSON:\n${JSON.stringify(input)}`;
    if (attempt > 0) text += "\n\nYour previous reply did not match the schema. Reply with ONE JSON object that matches it exactly.";
    content.push({ type: "text", text });

    // Fresh headers only: client IP and Cloudflare headers are never forwarded.
    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": env.ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: env.ANTHROPIC_MODEL ?? "claude-sonnet-4-5",
        max_tokens: task.maxTokens,
        temperature: task.temperature,
        system,
        messages: [{ role: "user", content }],
      }),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as AnthropicResponse;
    const out = (data.content ?? []).filter((b) => b.type === "text").map((b) => b.text ?? "").join("");
    try {
      const parsed = extractJson(out);
      if (validate(task.schema, parsed).length === 0) return parsed;
    } catch {
      // fall through to retry
    }
  }
  return null;
}

async function handleAi(request: Request, env: Env, taskName: string): Promise<Response> {
  if (request.method !== "POST") return fail(405, "method_not_allowed");
  if (!isTaskName(taskName)) return fail(404, "unknown_task");
  const task = TASKS[taskName];

  const declared = Number(request.headers.get("content-length") ?? "0");
  if (declared > MAX_BODY_BYTES) return fail(413, "too_large");

  const gated = await gate(request, env, env.AI_LIMITER, "ai");
  if (gated) return gated;

  const raw = await request.text();
  if (raw.length > MAX_BODY_BYTES) return fail(413, "too_large");

  let body: unknown;
  try {
    body = JSON.parse(raw);
  } catch {
    return fail(400, "invalid_json");
  }
  if (!isPlainObject(body) || !isPlainObject(body.input)) return fail(400, "missing_input");
  const input = body.input;
  if (containsForbiddenKey(input)) return fail(400, "identifiers_not_allowed");

  const imagesRaw = body.images ?? [];
  if (!Array.isArray(imagesRaw)) return fail(400, "invalid_images");
  if (imagesRaw.length < task.minImages || imagesRaw.length > task.maxImages) return fail(400, "wrong_image_count");
  const images: ImageIn[] = [];
  for (const img of imagesRaw) {
    if (!isPlainObject(img) || typeof img.media_type !== "string" || typeof img.data !== "string") return fail(400, "invalid_images");
    if (!ALLOWED_MEDIA.has(img.media_type) || img.data.length > MAX_IMAGE_B64 || !/^[A-Za-z0-9+/=]+$/.test(img.data)) {
      return fail(400, "invalid_images");
    }
    images.push({ media_type: img.media_type, data: img.data });
  }

  const result = await callModel(env, task, input, images);
  if (result === null) return fail(502, "model_output_invalid");
  return json(200, result);
}

function parseCoord(v: string | null, limit: number): string | null {
  if (v === null) return null;
  const n = Number(v);
  if (!Number.isFinite(n) || Math.abs(n) > limit) return null;
  return (Math.round(n * 1e4) / 1e4).toFixed(4);
}

function parseRange(v: string | null, min: number, max: number, dflt: number): number | null {
  if (v === null || v === "") return dflt;
  const n = Number(v);
  if (!Number.isFinite(n) || n < min || n > max) return null;
  return Math.round(n);
}

async function handleStreetView(request: Request, env: Env, url: URL): Promise<Response> {
  if (request.method !== "GET") return fail(405, "method_not_allowed");
  const gated = await gate(request, env, env.MAPS_LIMITER, "maps");
  if (gated) return gated;

  const lat = parseCoord(url.searchParams.get("lat"), 90);
  const lng = parseCoord(url.searchParams.get("lng"), 180);
  const heading = parseRange(url.searchParams.get("heading"), 0, 360, 0);
  const fov = parseRange(url.searchParams.get("fov"), 10, 120, 90);
  const pitch = parseRange(url.searchParams.get("pitch"), -90, 90, 0);
  if (lat === null || lng === null || heading === null || fov === null || pitch === null) return fail(400, "invalid_params");

  const g = new URL("https://maps.googleapis.com/maps/api/streetview");
  g.searchParams.set("size", "640x640");
  g.searchParams.set("location", `${lat},${lng}`);
  g.searchParams.set("heading", String(heading));
  g.searchParams.set("fov", String(fov));
  g.searchParams.set("pitch", String(pitch));
  g.searchParams.set("source", "outdoor");
  g.searchParams.set("return_error_code", "true");
  g.searchParams.set("key", env.GOOGLE_MAPS_KEY);

  const upstream = await fetch(g.toString(), { method: "GET" });
  if (upstream.status === 404) return fail(404, "no_imagery");
  if (!upstream.ok) return fail(502, "upstream_error");
  const bytes = await upstream.arrayBuffer();
  return new Response(bytes, {
    status: 200,
    headers: { ...BASE_HEADERS, "Content-Type": upstream.headers.get("content-type") ?? "image/jpeg" },
  });
}

interface StreetViewMeta {
  status?: string;
  date?: string;
  location?: { lat?: number; lng?: number };
}

// Address-free lookup: Street View metadata only (no-charge endpoint). Never returns an address.
async function handleGeocodeFree(request: Request, env: Env, url: URL): Promise<Response> {
  if (request.method !== "GET") return fail(405, "method_not_allowed");
  const gated = await gate(request, env, env.MAPS_LIMITER, "maps");
  if (gated) return gated;

  const lat = parseCoord(url.searchParams.get("lat"), 90);
  const lng = parseCoord(url.searchParams.get("lng"), 180);
  if (lat === null || lng === null) return fail(400, "invalid_params");

  const g = new URL("https://maps.googleapis.com/maps/api/streetview/metadata");
  g.searchParams.set("location", `${lat},${lng}`);
  g.searchParams.set("source", "outdoor");
  g.searchParams.set("key", env.GOOGLE_MAPS_KEY);

  const upstream = await fetch(g.toString(), { method: "GET" });
  if (!upstream.ok) return fail(502, "upstream_error");
  const meta = (await upstream.json()) as StreetViewMeta;
  const pLat = meta.location?.lat;
  const pLng = meta.location?.lng;
  return json(200, {
    status: meta.status ?? "UNKNOWN",
    has_imagery: meta.status === "OK",
    capture_date: meta.date ?? null,
    pano_location:
      typeof pLat === "number" && typeof pLng === "number"
        ? { lat: Math.round(pLat * 1e4) / 1e4, lng: Math.round(pLng * 1e4) / 1e4 }
        : null,
  });
}

async function route(request: Request, env: Env): Promise<Response> {
  const url = new URL(request.url);
  const ai = /^\/v1\/ai\/([a-z_]{1,40})$/.exec(url.pathname);
  if (ai) return handleAi(request, env, ai[1]);
  if (url.pathname === "/v1/maps/streetview") return handleStreetView(request, env, url);
  if (url.pathname === "/v1/maps/geocode-free") return handleGeocodeFree(request, env, url);
  if (url.pathname === "/healthz" && request.method === "GET") return json(200, { ok: true });
  return fail(404, "not_found");
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      return await route(request, env);
    } catch {
      // Deliberately no logging: the error could contain request data.
      return fail(500, "internal_error");
    }
  },
} satisfies ExportedHandler<Env>;

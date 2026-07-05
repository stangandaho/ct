/**
 * Cloudflare Worker — ct package website assistant.
 *
 * Holds the Anthropic API key server-side and answers camera-trap questions
 * using the bundled ct documentation. Streams the reply back to the browser
 * widget (pkgdown/extra.js).
 *
 * Deploy: see assistant/README.md
 */

import Anthropic from "@anthropic-ai/sdk";
// Bundled at build time via the [[rules]] Text rule in wrangler.toml.
// Regenerate with: Rscript data-raw/build_assistant_kb.R
import CT_DOCS from "./ct_knowledge.txt";

export interface Env {
  ANTHROPIC_API_KEY: string;
  RATE_LIMIT: KVNamespace;
  ALLOWED_ORIGIN: string; // e.g. "https://stangandaho.github.io"
}

// ---- Tunables -------------------------------------------------------------
const MODEL = "claude-opus-4-8"; // swap to claude-sonnet-4-6 / claude-haiku-4-5 to cut cost
const MAX_TOKENS = 2048;
const RATE_LIMIT_PER_MIN = 10; // requests per IP per minute
const MAX_MESSAGES = 20; // conversation turns accepted per request
const MAX_CHARS_PER_MESSAGE = 4000; // reject pathologically long inputs

const SYSTEM_PROMPT = `You are the assistant for the "ct" R package, a toolkit
for camera-trap data analysis: media metadata management (via ExifTool), data
preparation (independence filtering, datetime correction, occupancy format),
analysis (diversity, activity overlap, temporal shift, density estimation,
spatial coverage, survey design), and visualisation.

Rules:
- Answer ONLY using the ct documentation provided below.
- When you reference a function, name it exactly (e.g. ct_fit_rem(),
  ct_independence(), ct_read_metadata()) and show a short, runnable R example.
- Prefer the package's own example datasets (pendjari, ctdp, duikers, ACBR,
  rest_detection, rest_station, penessoulou) in examples.
- If the docs do not cover something, say so plainly and point the user to
  https://stangandaho.github.io/ct/ . Never invent functions or arguments.
- Keep answers focused on using ct for camera-trap workflows. Be concise and
  practical; lead with the answer, then the example.

<ct_documentation>
${CT_DOCS}
</ct_documentation>`;

type ChatMessage = { role: "user" | "assistant"; content: string };

// ---- CORS helpers ---------------------------------------------------------
// ALLOWED_ORIGIN may be a comma-separated list so you can test locally, e.g.
//   "https://stangandaho.github.io,http://localhost:4321,http://127.0.0.1:4321"
function allowedOrigins(env: Env): string[] {
  return env.ALLOWED_ORIGIN.split(",").map((s) => s.trim()).filter(Boolean);
}

// Returns the request's Origin if it is allowed, otherwise null.
function matchOrigin(req: Request, env: Env): string | null {
  const origin = req.headers.get("origin");
  return origin && allowedOrigins(env).includes(origin) ? origin : null;
}

function corsHeaders(origin: string): Record<string, string> {
  return {
    "access-control-allow-origin": origin,
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers": "content-type",
    "access-control-max-age": "86400",
    vary: "origin",
  };
}

function json(body: unknown, status: number, origin: string): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json", ...corsHeaders(origin) },
  });
}

// ---- Fixed-window rate limit (KV-backed) ----------------------------------
async function isRateLimited(env: Env, ip: string): Promise<boolean> {
  const windowKey = `rl:${ip}:${Math.floor(Date.now() / 60000)}`;
  const current = parseInt((await env.RATE_LIMIT.get(windowKey)) ?? "0", 10);
  if (current >= RATE_LIMIT_PER_MIN) return true;
  // TTL a little over the window so stale counters self-expire.
  await env.RATE_LIMIT.put(windowKey, String(current + 1), { expirationTtl: 120 });
  return false;
}

// ---- Input validation -----------------------------------------------------
function validate(payload: unknown): ChatMessage[] | null {
  if (typeof payload !== "object" || payload === null) return null;
  const messages = (payload as { messages?: unknown }).messages;
  if (!Array.isArray(messages) || messages.length === 0) return null;
  if (messages.length > MAX_MESSAGES) return null;

  const clean: ChatMessage[] = [];
  for (const m of messages) {
    if (typeof m !== "object" || m === null) return null;
    const { role, content } = m as Record<string, unknown>;
    if (role !== "user" && role !== "assistant") return null;
    if (typeof content !== "string" || content.length === 0) return null;
    if (content.length > MAX_CHARS_PER_MESSAGE) return null;
    clean.push({ role, content });
  }
  // The first and last message must be from the user.
  if (clean[0].role !== "user" || clean[clean.length - 1].role !== "user") return null;
  return clean;
}

// ---- Handler --------------------------------------------------------------
export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const origin = matchOrigin(req, env);
    // Header value for rejected requests (browser blocks them regardless).
    const hdrOrigin = origin ?? allowedOrigins(env)[0] ?? "";

    if (req.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: corsHeaders(hdrOrigin) });
    }
    if (req.method !== "POST") {
      return json({ error: "Method not allowed" }, 405, hdrOrigin);
    }
    if (origin === null) {
      return json({ error: "Forbidden origin" }, 403, hdrOrigin);
    }

    const ip = req.headers.get("CF-Connecting-IP") ?? "unknown";
    if (await isRateLimited(env, ip)) {
      return json({ error: "Rate limit exceeded. Please wait a moment." }, 429, origin);
    }

    let payload: unknown;
    try {
      payload = await req.json();
    } catch {
      return json({ error: "Invalid JSON" }, 400, origin);
    }

    const messages = validate(payload);
    if (!messages) {
      return json({ error: "Invalid request shape" }, 400, origin);
    }

    const client = new Anthropic({ apiKey: env.ANTHROPIC_API_KEY });

    const anthropicStream = client.messages.stream({
      model: MODEL,
      max_tokens: MAX_TOKENS,
      // Cache the large doc-laden system prompt so repeat questions are cheap.
      system: [
        { type: "text", text: SYSTEM_PROMPT, cache_control: { type: "ephemeral" } },
      ],
      messages,
    });

    const encoder = new TextEncoder();
    const body = new ReadableStream({
      async start(controller) {
        try {
          for await (const text of anthropicStream.textStream) {
            controller.enqueue(encoder.encode(text));
          }
        } catch (err) {
          controller.enqueue(
            encoder.encode("\n\n_Sorry — the assistant hit an error. Please try again._")
          );
          console.error("Anthropic stream error:", err);
        } finally {
          controller.close();
        }
      },
    });

    return new Response(body, {
      status: 200,
      headers: {
        "content-type": "text/plain; charset=utf-8",
        "cache-control": "no-store",
        ...corsHeaders(origin),
      },
    });
  },
};

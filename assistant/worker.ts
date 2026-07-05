/**
 * Cloudflare Worker — ct package website assistant.
 *
 * Uses Cloudflare Workers AI (free daily allowance, open models) to answer
 * camera-trap questions. A lightweight keyword retriever selects only the
 * most relevant sections of the ct documentation for each question, so the
 * request stays small and cheap (no vector DB, no embeddings, no API key).
 *
 * Deploy: see assistant/README.md
 */

// Bundled at build time via the [[rules]] Text rule in wrangler.toml.
// Regenerate with: Rscript data-raw/build_assistant_kb.R
import CT_DOCS from "./ct_knowledge.txt";

export interface Env {
  // Workers AI binding (configured as [ai] binding = "AI" in wrangler.toml).
  AI: { run: (model: string, options: Record<string, unknown>) => Promise<any> };
  RATE_LIMIT: KVNamespace;
  ALLOWED_ORIGIN: string;
}

// ---- Tunables -------------------------------------------------------------
// Browse other free models at https://developers.cloudflare.com/workers-ai/models/
// Bigger/better (more Neurons): "@cf/meta/llama-3.3-70b-instruct-fp8-fast"
const MODEL = "@cf/meta/llama-3.1-8b-instruct";
const MAX_TOKENS = 1024;
const RATE_LIMIT_PER_MIN = 10;
const MAX_MESSAGES = 20;
const MAX_CHARS_PER_MESSAGE = 4000;

// Retrieval: how many doc sections to include, and the total size budget.
const RETRIEVE_TOP_K = 6;
const MAX_SECTION_CHARS = 3000; // cap any single (e.g. vignette) section
const CONTEXT_CHAR_BUDGET = 16000; // ~4k tokens of context per request

const SYSTEM_INSTRUCTIONS = `You are the assistant for the "ct" R package, a
toolkit for camera-trap data analysis: media metadata management (via ExifTool),
data preparation (independence filtering, datetime correction, occupancy
format), analysis (diversity, activity overlap, temporal shift, density
estimation, spatial coverage, survey design), and visualisation.

Rules:
- Answer ONLY using the ct documentation provided in <ct_documentation>.
- When you reference a function, name it exactly (e.g. ct_fit_rem(),
  ct_independence()) and show a short, runnable R example.
- Prefer the package's own example datasets (pendjari, ctdp, duikers, ACBR,
  rest_detection, rest_station, penessoulou).
- If the documentation below does not cover the question, say so plainly and
  point the user to https://stangandaho.github.io/ct/ . Never invent functions
  or arguments.
- Be concise and practical: lead with the answer, then the example.`;

type ChatMessage = { role: "user" | "assistant"; content: string };

// ---- Retrieval index (built once at module load) --------------------------
// Split the corpus into sections on the "---" separators the build script
// writes between reference entries and vignettes.
const SECTIONS: string[] = CT_DOCS.split(/\n-{3,}\n/)
  .map((s) => s.trim())
  .filter((s) => s.length > 40);

function queryTerms(query: string): string[] {
  const seen = new Set<string>();
  for (const w of query.toLowerCase().split(/[^a-z0-9_]+/)) {
    if (w.length >= 3) seen.add(w);
  }
  return [...seen];
}

function scoreSection(section: string, terms: string[]): number {
  const lower = section.toLowerCase();
  const firstLine = lower.slice(0, lower.indexOf("\n") + 1 || 120);
  let score = 0;
  for (const t of terms) {
    let idx = 0;
    let count = 0;
    while (count < 5) {
      idx = lower.indexOf(t, idx);
      if (idx < 0) break;
      count++;
      idx += t.length;
    }
    score += count;
    if (firstLine.includes(t)) score += 3; // boost matches in the title line
  }
  return score;
}

// Pick the most relevant doc sections for a question, within the size budget.
function retrieve(query: string): string {
  const terms = queryTerms(query);
  if (terms.length === 0) return "";

  const ranked = SECTIONS.map((s) => ({ s, score: scoreSection(s, terms) }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, RETRIEVE_TOP_K);

  let budget = CONTEXT_CHAR_BUDGET;
  const picked: string[] = [];
  for (const { s } of ranked) {
    const piece = s.slice(0, MAX_SECTION_CHARS);
    if (piece.length > budget) break;
    picked.push(piece);
    budget -= piece.length;
  }
  return picked.join("\n\n---\n\n");
}

// ---- CORS helpers ---------------------------------------------------------
// ALLOWED_ORIGIN may be a comma-separated list so you can test locally, e.g.
//   "https://stangandaho.github.io,http://localhost:8000"
function allowedOrigins(env: Env): string[] {
  return env.ALLOWED_ORIGIN.split(",").map((s) => s.trim()).filter(Boolean);
}

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
  if (clean[0].role !== "user" || clean[clean.length - 1].role !== "user") return null;
  return clean;
}

// ---- Handler --------------------------------------------------------------
export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const origin = matchOrigin(req, env);
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

    // Retrieve doc context for the latest user question.
    const question = messages[messages.length - 1].content;
    const context = retrieve(question) || "(no matching documentation found)";
    const system = `${SYSTEM_INSTRUCTIONS}\n\n<ct_documentation>\n${context}\n</ct_documentation>`;

    try {
      const result = await env.AI.run(MODEL, {
        messages: [{ role: "system", content: system }, ...messages],
        max_tokens: MAX_TOKENS,
      });
      const answer =
        (result && typeof result.response === "string" && result.response.trim()) ||
        "Sorry, I couldn't generate an answer. Please rephrase your question.";

      return new Response(answer, {
        status: 200,
        headers: {
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "no-store",
          ...corsHeaders(origin),
        },
      });
    } catch (err) {
      console.error("Workers AI error:", err);
      // TEMP DEBUG: include the error detail while setting up. Replace with a
      // generic message before going fully public.
      const detail = err instanceof Error ? `${err.name}: ${err.message}` : String(err);
      return new Response("[assistant error] " + detail, {
        status: 200,
        headers: { "content-type": "text/plain; charset=utf-8", ...corsHeaders(origin) },
      });
    }
  },
};

/**
 * Cloudflare Worker — ct package website assistant (RAG).
 *
 * Fully free, entirely on Cloudflare:
 *   - Workers AI : embeddings (bge) + chat (Mistral)  — no API key
 *   - Vectorize : semantic vector search over the ct docs
 *
 * The docs are indexed by POSTing to /reindex (guarded by REINDEX_KEY).
 * At query time the question is embedded, the most semantically similar doc
 * chunks are retrieved, and the chat model answers from them.
 *
 * Deploy / index: see assistant/README.md
 */

// Bundled at build time via the [[rules]] Text rule in wrangler.toml.
// Regenerate with: Rscript data-raw/build_assistant_kb.R
import CT_DOCS_RAW from "./ct_knowledge.txt";

// Normalize line endings. The corpus can carry CRLF/CR, which breaks the
// "\n---\n" section split used by both the catalog and the chunker.
const CT_DOCS = CT_DOCS_RAW.replace(/\r\n?/g, "\n");

// Minimal shapes for the Workers AI + Vectorize bindings we use.
interface VectorizeMatch {
  id: string;
  score: number;
  metadata?: Record<string, unknown>;
}
interface Vectorize {
  query: (
    vector: number[],
    opts: { topK?: number; returnMetadata?: "all" | "indexed" | "none" }
  ) => Promise<{ matches: VectorizeMatch[] }>;
  upsert: (
    vectors: { id: string; values: number[]; metadata?: Record<string, unknown> }[]
  ) => Promise<unknown>;
}

export interface Env {
  AI: { run: (model: string, options: Record<string, unknown>) => Promise<any> };
  VECTORIZE: Vectorize;
  RATE_LIMIT: KVNamespace;
  ALLOWED_ORIGIN: string;
  REINDEX_KEY: string; // secret guarding POST /reindex
}

// Tunables
// Run `npx wrangler ai models` to see what is currently live on your account.
//const CHAT_MODEL = "@cf/mistralai/mistral-small-3.1-24b-instruct";
const CHAT_MODEL = "@cf/mistralai/mistral-small-3.1-24b-instruct";
const EMBED_MODEL = "@cf/baai/bge-base-en-v1.5"; // 768-dim; matches the index
const EMBED_DIM = 768;

const TOP_K = 8; // doc chunks retrieved per question
const MAX_CHUNK_CHARS = 1600; // chunk size for indexing (fits the embedder)
const EMBED_BATCH = 90; // texts embedded per Workers AI call

const MAX_TOKENS = 1536;
const RATE_LIMIT_PER_MIN = 10;
const MAX_MESSAGES = 20;
const MAX_CHARS_PER_MESSAGE = 12000; // larger, to allow an attached dataset profile

const SYSTEM_INSTRUCTIONS = `You are the assistant for the "ct" R package, a
toolkit for camera-trap data analysis: media metadata management (via ExifTool),
data preparation (independence filtering, datetime correction, occupancy
format), analysis (diversity, activity overlap, temporal shift, density
estimation, spatial coverage, survey design), and visualisation.

How to answer:
- A complete list of ct functions with their titles is given below under
  "Complete list of ct functions". Treat it as authoritative: if a function for
  the user's task appears there, USE it — never claim the package lacks a
  capability that is in that list. Map the user's intent to the right function
  even when their wording differs (e.g. "daily camera trap captures" =>
  ct_camera_day(); "activity change between periods" => ct_temporal_shift()).
- The <ct_documentation> section holds the detailed help (arguments and
  Examples) for the functions most relevant to this question. Base your R code
  on the "Examples" shown there and use the exact argument names. Do NOT invent
  arguments or syntax that is not in the documentation.
- Prefer the package's own datasets (pendjari, ctdp, duikers, ACBR,
  rest_detection, rest_station, penessoulou) in examples.
- If the user's message includes a block starting with "[Attached dataset",
  tailor the code to their exact column names, mapping them to the relevant ct
  arguments (e.g. datetime_column, species_column, deployment_column).
- Be concise: give the answer first, then a short runnable example.`;

type ChatMessage = { role: "user" | "assistant"; content: string };

// Chunking (shared by /reindex)
// Sections are separated by the "---" the build script writes between
// reference entries and vignettes; long ones are split further by paragraph.
function chunkDocs(doc: string): { id: string; text: string }[] {
  const sections = doc.split(/\n-{3,}\n/).map((s) => s.trim()).filter((s) => s.length > 40);
  const chunks: { id: string; text: string }[] = [];
  let n = 0;
  for (const sec of sections) {
    const title = sec.slice(0, sec.indexOf("\n") >= 0 ? sec.indexOf("\n") : 120);
    if (sec.length <= MAX_CHUNK_CHARS) {
      chunks.push({ id: `c${n++}`, text: sec });
      continue;
    }
    const paras = sec.split(/\n\s*\n/);
    let buf = "";
    for (const p of paras) {
      if (buf && (buf + "\n\n" + p).length > MAX_CHUNK_CHARS) {
        chunks.push({ id: `c${n++}`, text: `${title}\n\n${buf}` });
        buf = p;
      } else {
        buf = buf ? `${buf}\n\n${p}` : p;
      }
    }
    if (buf) chunks.push({ id: `c${n++}`, text: `${title}\n\n${buf}` });
  }
  return chunks;
}

// A compact, always-in-prompt index of every ct function and its title, so the
// model can map intent -> the right function name even when vector retrieval
// misses that function's chunk. Built once at module load.
function buildCatalog(doc: string): string {
  const seen = new Set<string>();
  const entries: string[] = [];
  for (const sec of doc.split(/\n-{3,}\n/)) {
    const m = sec.match(/\b(ct_[A-Za-z0-9_.]+)\s*\(/);
    if (!m) continue;
    const name = m[1];
    if (seen.has(name)) continue;
    seen.add(name);
    const title =
      sec
        .split("\n")
        .map((s) => s.trim())
        .find((s) => s && !s.startsWith("#") && !/^[-=]+$/.test(s)) ?? "";
    entries.push(`- ${name}() — ${title.slice(0, 90)}`);
  }
  return entries.sort().join("\n");
}
const CATALOG = buildCatalog(CT_DOCS);

async function embedTexts(env: Env, texts: string[]): Promise<number[][]> {
  const out: number[][] = [];
  for (let i = 0; i < texts.length; i += EMBED_BATCH) {
    const batch = texts.slice(i, i + EMBED_BATCH);
    const res = await env.AI.run(EMBED_MODEL, { text: batch });
    for (const v of res.data as number[][]) out.push(v);
  }
  return out;
}

// Build/refresh the Vectorize index from the bundled docs.
async function reindex(env: Env): Promise<number> {
  const chunks = chunkDocs(CT_DOCS);
  const vectors = await embedTexts(
    env,
    chunks.map((c) => c.text)
  );
  let indexed = 0;
  const UPSERT_BATCH = 500;
  for (let i = 0; i < chunks.length; i += UPSERT_BATCH) {
    const slice = chunks.slice(i, i + UPSERT_BATCH).map((c, j) => ({
      id: c.id,
      values: vectors[i + j],
      metadata: { text: c.text },
    }));
    await env.VECTORIZE.upsert(slice);
    indexed += slice.length;
  }
  return indexed;
}

// Semantic retrieval
// Workers AI text models vary in output shape. Pull the generated text from
// whichever field this model uses.
function extractAnswer(result: any): string {
  if (!result) return "";
  if (typeof result === "string") return result.trim();
  if (typeof result.response === "string") return result.response.trim();
  if (result.response && typeof result.response.response === "string") {
    return result.response.response.trim();
  }
  if (typeof result.output_text === "string") return result.output_text.trim();
  if (Array.isArray(result.choices) && result.choices[0]) {
    const c = result.choices[0];
    if (c.message && typeof c.message.content === "string") return c.message.content.trim();
    if (typeof c.text === "string") return c.text.trim();
  }
  return "";
}

async function retrieve(env: Env, question: string): Promise<string> {
  const [vector] = await embedTexts(env, [question]);
  const res = await env.VECTORIZE.query(vector, { topK: TOP_K, returnMetadata: "all" });
  return res.matches
    .map((m) => (typeof m.metadata?.text === "string" ? m.metadata.text : ""))
    .filter(Boolean)
    .join("\n\n---\n\n");
}

// CORS helpers
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

// Fixed-window rate limit (KV-backed)
async function isRateLimited(env: Env, ip: string): Promise<boolean> {
  const windowKey = `rl:${ip}:${Math.floor(Date.now() / 60000)}`;
  const current = parseInt((await env.RATE_LIMIT.get(windowKey)) ?? "0", 10);
  if (current >= RATE_LIMIT_PER_MIN) return true;
  await env.RATE_LIMIT.put(windowKey, String(current + 1), { expirationTtl: 120 });
  return false;
}

// Input validation --
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

// Handler -
export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);

    // Admin: (re)build the vector index. Server-to-server, no CORS needed.
    //   curl -X POST https://<worker>/reindex -H "x-reindex-key: <REINDEX_KEY>"
    if (req.method === "POST" && url.pathname.replace(/\/$/, "") === "/reindex") {
      if (req.headers.get("x-reindex-key") !== env.REINDEX_KEY) {
        return new Response("Forbidden", { status: 403 });
      }
      try {
        const indexed = await reindex(env);
        return Response.json({ ok: true, indexed });
      } catch (err) {
        return new Response("Reindex error: " + String(err), { status: 500 });
      }
    }

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

    try {
      const question = messages[messages.length - 1].content;
      const context = (await retrieve(env, question)) || "(no matching documentation found)";
      const system =
        `${SYSTEM_INSTRUCTIONS}\n\n` +
        `## Complete list of ct functions (exhaustive; use these EXACT names)\n${CATALOG}\n\n` +
        `<ct_documentation>\n${context}\n</ct_documentation>`;

      const result = await env.AI.run(CHAT_MODEL, {
        messages: [{ role: "system", content: system }, ...messages],
        max_tokens: MAX_TOKENS,
      });
      let answer = extractAnswer(result);
      if (!answer) {
        // TEMP DEBUG: reveal the model's actual output shape so extraction can
        // be fixed. Remove once the assistant is answering.
        console.error("Empty answer. Result shape:", JSON.stringify(result));
        answer = "[assistant debug] no text field in model result: " +
          JSON.stringify(result).slice(0, 700);
      }

      return new Response(answer, {
        status: 200,
        headers: {
          "content-type": "text/plain; charset=utf-8",
          "cache-control": "no-store",
          ...corsHeaders(origin),
        },
      });
    } catch (err) {
      console.error("Assistant error:", err);
      // TEMP DEBUG: surface the error while setting up; make generic later.
      const detail = err instanceof Error ? `${err.name}: ${err.message}` : String(err);
      return new Response("[assistant error] " + detail, {
        status: 200,
        headers: { "content-type": "text/plain; charset=utf-8", ...corsHeaders(origin) },
      });
    }
  },
};

// EMBED_DIM is exported for reference when creating the Vectorize index:
//   npx wrangler vectorize create ct-docs --dimensions=768 --metric=cosine
export { EMBED_DIM };

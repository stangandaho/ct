# ct website assistant

A small [Cloudflare Worker](https://workers.cloudflare.com/) that powers the
"Ask ct" chat widget on <https://stangandaho.github.io/ct/>. It answers
camera-trap questions using the ct documentation via **retrieval-augmented
generation (RAG)** — and it runs entirely on Cloudflare's **free** tier, with
**no external API key**.

Everything is Cloudflare Workers AI + Vectorize:

- **Workers AI** — embeddings (`bge-base-en-v1.5`) and chat (`mistral-small-3.1-24b-instruct`)
- **Vectorize** — semantic vector search over the ct docs

```
                       ┌──────────────── INDEX (offline, via /reindex) ───────────────┐
                       │  ct_knowledge.txt → chunks → bge embeddings → Vectorize index │
                       └───────────────────────────────────────────────────────────────┘

pkgdown site (browser)                     this Worker                        Workers AI
  extra.js widget ──POST /──▶  embed question ─▶ Vectorize top-K chunks ─▶ Mistral ─▶ answer
      ▲                                                                                │
      └──────────────────────────── answer (plain text) ◀──────────────────────────────┘
```

Why RAG: the docs corpus (~85k tokens) is far too large to send to a small open
model on every request, and keyword matching fails when the user's words differ
from the docs' wording (e.g. "activity change between periods" vs "temporal
shift"). Embedding-based retrieval matches on *meaning* and sends only the few
most relevant chunks.

## Files

| File               | Purpose                                                        |
| ------------------ | -------------------------------------------------------------- |
| `worker.ts`        | The Worker: RAG query path, `/reindex` route, rate limiting.   |
| `wrangler.toml`    | Cloudflare config (AI, Vectorize, KV bindings; text bundle).   |
| `ct_knowledge.txt` | Generated docs corpus, bundled into the Worker.                |
| `package.json`     | Node dependencies (`wrangler`, types).                         |

`ct_knowledge.txt` is produced by `data-raw/build_assistant_kb.R`, which writes
it straight into this directory.

## One-time setup

Run everything below from the `assistant/` directory unless noted.

1. **Generate the knowledge base** (from the package root):

   ```sh
   Rscript data-raw/build_assistant_kb.R
   ```

2. **Install dependencies:**

   ```sh
   npm install
   ```

3. **Create the rate-limit KV namespace** and paste the returned `id` into
   `wrangler.toml` (`[[kv_namespaces]]`):

   ```sh
   npx wrangler kv namespace create RATE_LIMIT
   ```

4. **Create the Vectorize index** (768 dims to match the `bge` embedder):

   ```sh
   npx wrangler vectorize create ct-docs --dimensions=768 --metric=cosine
   ```

5. **Set the reindex secret** (any random string — it guards `POST /reindex`):

   ```sh
   npx wrangler secret put REINDEX_KEY
   ```

6. **Set your site origin** in `wrangler.toml` (`ALLOWED_ORIGIN`) so only your
   pkgdown site may call the Worker. It accepts a comma-separated list, which is
   handy for local testing, e.g.
   `"https://stangandaho.github.io,http://localhost:8000"`.

## Deploy and index

```sh
# 1. Deploy the Worker
npx wrangler deploy

# 2. Build the vector index from the bundled docs (see rule below)
curl -X POST https://ct-assistant.<you>.workers.dev/reindex \
  -H "x-reindex-key: THE_KEY_FROM_STEP_5"
```

`/reindex` returns `{"ok":true,"indexed":N}`. Wait a few seconds for Vectorize
to make the vectors queryable, then test the widget.

Finally, copy the deployed URL into `pkgdown/extra.js` (the `ENDPOINT`
constant) and rebuild the site:

```r
pkgdown::build_site()
```

## ⚠️ Reindex after every docs update

The Vectorize index is a **snapshot** of `ct_knowledge.txt` at index time. It
does **not** update automatically when you deploy. Whenever the documentation
changes (new package version, edited vignettes, new functions), you must do
**both** of these, in order:

```sh
# 1. Regenerate the corpus (from the package root)
Rscript data-raw/build_assistant_kb.R

# 2. Redeploy so the Worker bundles the new ct_knowledge.txt
cd assistant && npx wrangler deploy

# 3. Rebuild the index so search reflects the new docs
curl -X POST https://ct-assistant.<you>.workers.dev/reindex \
  -H "x-reindex-key: YOUR_REINDEX_KEY"
```

Skipping step 3 leaves the assistant answering from **stale** documentation.
`/reindex` upserts by chunk id, so re-running it simply overwrites existing
vectors — it is safe to run any time.

## Tuning

Edit the constants at the top of `worker.ts`:

- `CHAT_MODEL` — generation model. `@cf/mistralai/mistral-small-3.1-24b-instruct`
  is a good free default; a 70B-class model gives better answers but uses more
  of the daily Neuron allowance. Run `npx wrangler ai models` to see what is
  currently available (the catalog rotates; deprecated models return AiError
  5028).
- `EMBED_MODEL` / `EMBED_DIM` — embedding model and its dimension. **If you
  change this, the dimension must match the Vectorize index**, so recreate the
  index (`wrangler vectorize delete ct-docs` then `create` with the new
  `--dimensions`) and reindex.
- `TOP_K` — how many chunks are retrieved per question (default 6).
- `MAX_CHUNK_CHARS` — chunk size used at index time (default 1600).
- `RATE_LIMIT_PER_MIN`, `MAX_TOKENS`, `MAX_MESSAGES`, `MAX_CHARS_PER_MESSAGE` —
  request/response caps.

## Cost

Free. Workers AI has a daily Neuron allowance and Vectorize a free tier; a docs
widget stays well within both. There is no per-token bill and no API key.

## Debugging

- `npx wrangler tail` streams live Worker logs (errors are logged there).
- The Worker currently returns upstream error detail to the caller
  (`[assistant error] ...`) to ease setup. Before going fully public, replace
  that branch in `worker.ts` with a generic message so internals aren't exposed.
- Test the backend directly, bypassing the browser/CORS:

  ```sh
  curl -sS -X POST https://ct-assistant.<you>.workers.dev \
    -H "content-type: application/json" \
    -H "origin: https://stangandaho.github.io" \
    -d '{"messages":[{"role":"user","content":"How do I estimate density with REM?"}]}'
  ```

## Note on bundle size

`ct_knowledge.txt` is bundled into the Worker. Cloudflare's free tier caps the
compressed script at ~1 MB. For the current ct docs this is comfortable; if the
corpus grows past the limit, move the text to KV or R2 and fetch it at cold
start instead of importing it.

# ct website assistant

A small [Cloudflare Worker](https://workers.cloudflare.com/) that powers the
"Ask ct" chat widget on <https://stangandaho.github.io/ct/>. It holds the
Anthropic API key server-side and answers camera-trap questions using the
bundled ct documentation.

```
pkgdown site (browser)          this Worker                 Anthropic API
  extra.js widget ──POST /──▶  holds API key       ─────▶   Claude
      ▲                        + ct docs context            (streams answer)
      └────────── streamed reply ◀──────────────────────────────┘
```

## Files

| File                    | Purpose                                             |
| ----------------------- | --------------------------------------------------- |
| `worker.ts`             | The Worker: validation, rate limiting, Claude call. |
| `wrangler.toml`         | Cloudflare config (KV binding, text-bundle rule).   |
| `ct_knowledge.txt`      | Generated docs corpus (see below). Not committed by hand. |
| `package.json`          | Node dependencies (`@anthropic-ai/sdk`, `wrangler`).|

`ct_knowledge.txt` is produced by `data-raw/build_assistant_kb.R`, which writes
it straight into this directory.

## One-time setup

1. **Generate the knowledge base** (from the package root):

   ```sh
   Rscript data-raw/build_assistant_kb.R
   ```

2. **Install dependencies:**

   ```sh
   cd assistant
   npm install
   ```

3. **Create the rate-limit KV namespace** and paste the returned `id` into
   `wrangler.toml` (`[[kv_namespaces]]`):

   ```sh
   npx wrangler kv namespace create RATE_LIMIT
   ```

4. **Store the API key as a secret** (never put it in `wrangler.toml`):

   ```sh
   npx wrangler secret put ANTHROPIC_API_KEY
   ```

5. **Set your site origin** in `wrangler.toml` (`ALLOWED_ORIGIN`) so only your
   pkgdown site may call the Worker.

## Deploy

```sh
npx wrangler deploy
```

Copy the deployed URL (e.g. `https://ct-assistant.<you>.workers.dev`) into
`pkgdown/extra.js` (the `ENDPOINT` constant), then rebuild the site:

```r
pkgdown::build_site()
```

## Update on each release

Re-run the harvest and redeploy so the assistant tracks the current API:

```sh
Rscript data-raw/build_assistant_kb.R
cd assistant && npx wrangler deploy
```

## Tuning

Edit the constants at the top of `worker.ts`:

- `MODEL` — defaults to `claude-opus-4-8`. For a high-traffic public widget,
  `claude-sonnet-4-6` or `claude-haiku-4-5` are cheaper.
- `RATE_LIMIT_PER_MIN` — requests allowed per IP per minute (default 10).
- `MAX_TOKENS`, `MAX_MESSAGES`, `MAX_CHARS_PER_MESSAGE` — response and input caps.

The large documentation system prompt is sent with `cache_control` (prompt
caching), so repeat questions cost roughly a tenth of the first. Confirm it is
working by logging `usage.cache_read_input_tokens` on the stream's final message.

## Note on bundle size

`ct_knowledge.txt` is bundled into the Worker. Cloudflare's free tier caps the
compressed script at ~1 MB. For the current ct docs this is comfortable; if the
corpus grows past the limit, move the text to KV or R2 and fetch it at cold
start instead of importing it.

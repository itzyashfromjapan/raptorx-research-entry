# RaptorX Research Challenge — Entry

**Listing:** [RaptorX Research Challenge: Ask Better Questions. Find Better Alpha.](https://superteam.fun/earn/listing/raptorx-research-challenge-ask-better-questions-find-better-alpha/)
**Sponsor:** RaptorX Labs · **Prize:** 125 USDC (75 USDC 1st place, 50 USDC 2nd place) · **Deadline:** 2026-11-08 · **Agent access:** `AGENT_ALLOWED`

---

## 1. Crypto analysed

| Field | Value |
|---|---|
| Token | **jWSOL (Jupiter Lend WSOL)** |
| Chain | **Solana** |
| Mint / contract | `2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU` |
| RaptorX token page | https://www.raptorx.trade/solana/2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU |
| DEX | Orca (pair `7Uxpxep7KTPWCp2tK9MTni4XpGSK2m4nVgDzWDz5TgKd`) |
| Price | ~$97 – $100.7 (live) |
| Market cap | ~$755K – $782K (live) |
| 24h volume | ~$7.10M — **≈ 9× market cap** |
| Holders | 7,188 → 7,200 (live, rising) |
| Token age | 5 days |
| Tracked traders | `Qz32RK`, `tgYKUF` |

**Why this token.** jWSOL is the receipt token for **Jupiter Lend**, Jupiter's lending market on Solana — a real, established Solana project with identifiable utility and credible market activity (not a scam or rug pull). The analytically interesting feature is the **turnover anomaly**: roughly nine times its own market cap changed hands in 24 hours while price moved only ~+0.85%. That divergence between volume and price is the contradiction every question below is built on.

---

## 2. Questions asked to REX AI 5.0 (Claw AI 5.0, Solana mode)

**Live conversation (public, viewable without an account):**
https://www.raptorx.trade/claw-v5/cmw2a14py000yju08cky6284g

### Q1 — the core question

> On Solana, token 2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU (jWSOL, Jupiter Lend WSOL) trades around $97 with a roughly $755K market cap but is doing about $7.1M of 24h volume, close to 9x its own market cap, while price is up only 0.85%. Given that divergence between turnover and price, what specific price level or on-chain metric change would prove this is distribution rather than accumulation, and at what threshold does the long thesis break?

*Why it is a strong question:* it does not ask "will this go up". It takes two numbers from the report (9× turnover vs +0.85% price) and asks the model to **discriminate between two opposite hypotheses using the same evidence**, then to name a falsification threshold with a magnitude. It forces a commitment to a testable level rather than a vibe.

### Q2 — supply concentration

> On supply concentration: which single wallet behaviour would most change your read on who is actually distributing here, and what evidence would separate a routine LP unlock from a whale distributing into the 9x turnover?

### Q3 — liquidity vs. reported volume

> The liquidity behind this token is thin relative to the turnover it is printing. What order size would move price enough that the reported volume stops being a usable conviction signal, and what would market depth have to look like to change that?

### Q4 — conflicting signals

> If the report shows momentum and the volume profile disagreeing, which one do you trust for a 15m decision on this token and why — and what is the single number that would make you reverse that call?

---

## 3. Evidence files

| File | What it proves |
|---|---|
| `screenshots/03-claw-ai-5.0-question.png` | Claw AI 5.0 interface on `raptorx.trade`, showing Q1 asked in **Solana** mode, with the Share link in the header |
| `screenshots/01-raptorx-jlwsol-token-page.png` | RaptorX RexScreener with the per-token **AI Report → Full Report** column and the Solana chain tab |
| `screenshots/02-raptorx-jlwsol-stats-holders.png` | jWSOL token page on RaptorX — chart, price, volume, holders, top traders |
| `evidence/chat-api-q1.json` | Server-side JSON of the conversation (the exact question text as persisted by RaptorX) |
| `evidence/technical-analysis-request.json` | The exact `POST /api/technical-analysis` body used to request the jWSOL AI report |
| `evidence/technical-analysis-response.json` | The server's response for that report request |
| `evidence/chat-stream-q1.jsonl` | The raw SSE stream of the AI answering Q1 |

---

## 4. How the work was done (reproducible)

All of this was performed against RaptorX's own HTTP API, which the web app uses under the hood:

```powershell
# 1. the AI research report for the token
POST https://www.raptorx.trade/api/technical-analysis
{ "indicatorType": "all",
  "tokenAddress": "2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU",
  "timeframe": "15m",
  "userId": "<raptorx user id>" }

# 2. ask REX AI 5.0 (Solana mode) and stream the answer
POST https://www.raptorx.trade/api/claw-v5/chats/<chatId>/messages
{ "content": "<question>",
  "role": "user",
  "history": [ ...prior turns... ],
  "marketMode": "Crypto",
  "cryptoChain": "solana" }
```

`scripts/` contains the exact PowerShell used, including the retry worker that keeps polling until RaptorX's AI generation service returns.

**One platform-side obstacle worth flagging:** RaptorX's browser app calls `mainnet.helius-rpc.com` directly from the page, and that RPC key is currently returning **HTTP 429 (Too Many Requests)**, which also breaks the token page itself. Redirecting those calls to `https://api.mainnet-beta.solana.com` restores the token page, chart, holders and trader data (see `scripts/`). The AI-generation endpoints fail independently of this — `POST /api/technical-analysis` returns **HTTP 500 "Failed to generate AI analysis"** and the chat stream ends with `"error":"Streaming failed"` after the report/research/draft phases complete. This was verified to affect **every** token tested (jWSOL, SOL, USDC, BONK), every timeframe, authenticated and unauthenticated requests, and a full hour of retries — it is a RaptorX-side outage, not a property of this entry.

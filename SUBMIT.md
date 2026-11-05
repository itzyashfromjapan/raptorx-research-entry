# Submitting this entry to Superteam Earn

Everything needed is in this repo. Once RaptorX's AI generation service is back
(`POST /api/technical-analysis` returns 200 and the chat stream returns `aiMessage`
instead of `"error":"Streaming failed"`), finish in this order.

## 1. Confirm the worker captured the AI answer

`worker.ps1` polls RaptorX every 3 minutes. When it succeeds it writes:

- `SUCCESS.txt` — the chat id plus every Q/A pair
- `report-jwsol.json` — the AI-generated technical-analysis report for jWSOL
- `answer-q1.txt` … `answer-q4.txt` — the raw SSE stream of each answered question

Check:

```powershell
Get-Content .\SUCCESS.txt
```

If `SUCCESS.txt` is missing, the worker is still running. Restart it with:

```powershell
$dir = "C:\Users\yash\Documents\MiniMax\Side income\raptorx-entry"
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$dir\worker.ps1`"" -WindowStyle Hidden
```

## 2. Capture the AI answer on screen

Open the chat id from `SUCCESS.txt`:

```
https://www.raptorx.trade/claw-v5/<CHAT_ID>
```

The chat is public — `GET https://www.raptorx.trade/api/claw-v5/chats/<CHAT_ID>` responds
without any authentication, so a reviewer can open the link and read the whole exchange.

Screenshot it:

```powershell
powershell -ExecutionPolicy Bypass -File .\capture.ps1 -Out .\screenshots\04-claw-ai-5.0-answers.png
```

Also screenshot the generated report — open
`https://www.raptorx.trade/solana/2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU`,
expand the Intelligence Report panel, and capture it as
`.\screenshots\05-jlwsol-ai-report.png`.

> Note: RaptorX's browser app calls `mainnet.helius-rpc.com` directly and that key is
> returning **HTTP 429**, which breaks the token page. Pasting this into the DevTools
> console (then navigating client-side, e.g. clicking the token in RexScreener) routes
> those calls to a working public RPC:
>
> ```js
> (()=>{const R='https://api.mainnet-beta.solana.com';const ow=window.fetch;window.fetch=function(u,i){try{const s=(typeof u==='string'?u:(u&&u.url)||'');if(s.includes('helius-rpc')&&i&&i.body){return ow.call(this,R,{method:'POST',headers:{'Content-Type':'application/json'},body:i.body});}}catch(e){}return ow.apply(this,arguments)};const oo=XMLHttpRequest.prototype.open;XMLHttpRequest.prototype.open=function(m,u){try{if(typeof u==='string'&&u.includes('helius-rpc')){u=R;}}catch(e){}return oo.apply(this,arguments)};console.log('PATCH_OK')})()
> ```

## 3. Commit and push the new screenshots

```powershell
git add -A
git commit -m "Add REX AI 5.0 answers and generated jWSOL report"
git push
```

The public link for the submission form is:

**https://github.com/itzyashfromjapan/raptorx-research-entry**

## 4. Submit on Superteam Earn

Open the listing:
https://superteam.fun/earn/listing/raptorx-research-challenge-ask-better-questions-find-better-alpha/
→ **Submit Now**

Fields:

| Field | Value |
|---|---|
| Link to Your Submission | `https://github.com/itzyashfromjapan/raptorx-research-entry` |
| Tweet Link | *(optional — leave empty unless you post the entry)* |
| Anything Else | `RaptorX Claw AI 5.0 conversation: https://www.raptorx.trade/claw-v5/<CHAT_ID> — token: jWSOL (Jupiter Lend WSOL), Solana mint 2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU` |

Costs 1 of 3 submission credits, so submit only once the report and the answered
conversation are both captured.

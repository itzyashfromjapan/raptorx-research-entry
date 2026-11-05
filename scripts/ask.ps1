$ErrorActionPreference = 'Continue'
$base = 'https://www.raptorx.trade'
$out  = 'C:\Users\yash\Documents\MiniMax\Side income\raptorx-entry\raw-stream.txt'
$log  = 'C:\Users\yash\Documents\MiniMax\Side income\raptorx-entry\attempts.log'

$question = @'
On Solana, token 2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU (jWSOL, Jupiter Lend WSOL) trades around $97 with a roughly $755K market cap but is doing about $7.1M of 24h volume, close to 9x its own market cap, while price is up only 0.85%. Given that divergence between turnover and price, what specific price level or on-chain metric change would prove this is distribution rather than accumulation, and at what threshold does the long thesis break?
'@

function Post-Json([string]$url, [string]$json, [int]$timeoutSec = 120) {
  try {
    $r = Invoke-WebRequest -Uri $url -Method Post -Body $json -ContentType 'application/json' -TimeoutSec $timeoutSec -UseBasicParsing
    return @{ ok = $true; status = [int]$r.StatusCode; body = $r.Content }
  } catch {
    $sc = 0; $b = ''
    if ($_.Exception.Response) {
      $sc = [int]$_.Exception.Response.StatusCode
      try { $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream()); $b = $sr.ReadToEnd() } catch {}
    }
    return @{ ok = $false; status = $sc; body = $b; err = $_.Exception.Message }
  }
}

# --- 1. create a clean chat ---
$chatId = $null
$create = Post-Json "$base/api/claw-v5/chats" (@{ title = 'jWSOL research - RaptorX Research Challenge' } | ConvertTo-Json -Compress) 40
Add-Content $log "CREATE status=$($create.status) body=$($create.body)"
if ($create.ok -and $create.body) {
  try {
    $j = $create.body | ConvertFrom-Json
    if ($j.chat.id) { $chatId = $j.chat.id }
    elseif ($j.id) { $chatId = $j.id }
  } catch {}
}
if (-not $chatId) { $chatId = 'cmw2a14py000yju08cky6284g'; Add-Content $log "FALLBACK chat=$chatId" }
Write-Output "CHAT=$chatId"

# --- 2. retry the question until we get real content ---
$bodyObj = @{ content = $question; role = 'user'; history = @(); marketMode = 'Crypto'; cryptoChain = 'solana' }
$json = $bodyObj | ConvertTo-Json -Depth 6 -Compress

for ($i = 1; $i -le 8; $i++) {
  Write-Output "--- ATTEMPT $i ---"
  $resp = Post-Json "$base/api/claw-v5/chats/$chatId/messages" $json 150
  Add-Content $log "attempt=$i status=$($resp.status) len=$($resp.body.Length)"
  Write-Output ("status=" + $resp.status)
  if ($resp.body) {
    Set-Content -Path $out -Value $resp.body -Encoding UTF8
    $lines = $resp.body -split "`n"
    foreach ($ln in $lines) {
      if ($ln -match '"type":"(\w+)"') { Write-Output ("  evt: " + $Matches[1]) }
    }
    if ($resp.body -match '"type":"(aiMessage|chunk|reportDelta)"') {
      Write-Output "SUCCESS - content captured"
      Write-Output ("SAVED to " + $out)
      break
    }
    if ($resp.status -eq 402) { Write-Output ("QUOTA 402: " + $resp.body); break }
  }
  Start-Sleep -Seconds 12
}
Write-Output ("CHATID_FINAL=" + $chatId)

$ErrorActionPreference = 'Continue'
$base = 'https://www.raptorx.trade'
$dir  = 'C:\Users\yash\Documents\MiniMax\Side income\raptorx-entry'
$uid  = 'cmw29gq7n000blc08x6hxmt9p'
$done = Join-Path $dir 'SUCCESS.txt'

function Post-Json([string]$url, [string]$json, [int]$timeoutSec = 200) {
  try {
    $r = Invoke-WebRequest -Uri $url -Method Post -Body $json -ContentType 'application/json' -TimeoutSec $timeoutSec -UseBasicParsing
    return @{ ok=$true; status=[int]$r.StatusCode; body=$r.Content }
  } catch {
    $sc=0; $b=''
    if ($_.Exception.Response) {
      $sc=[int]$_.Exception.Response.StatusCode
      try { $sr=New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream()); $b=$sr.ReadToEnd() } catch {}
    }
    return @{ ok=$false; status=$sc; body=$b }
  }
}

$questions = @(
  'On Solana, token 2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU (jWSOL, Jupiter Lend WSOL) trades around $97 with a roughly $755K market cap but is doing about $7.1M of 24h volume, close to 9x its own market cap, while price is up only 0.85%. Given that divergence between turnover and price, what specific price level or on-chain metric change would prove this is distribution rather than accumulation, and at what threshold does the long thesis break?'
)

for ($i = 1; $i -le 40; $i++) {
  if (Test-Path $done) { Write-Output "ALREADY DONE"; break }
  $q = $questions[($i-1) % $questions.Count]
  $c = Post-Json "$base/api/claw-v5/chats" (@{ userId=$uid; title='jWSOL research - RaptorX Research Challenge' } | ConvertTo-Json -Compress) 40
  $chatId = $null
  if ($c.ok -and $c.body) { try { $j=$c.body|ConvertFrom-Json; $chatId = $j.chat.id } catch {} }
  if (-not $chatId) { Write-Output ("[$i] chat create failed: " + $c.status); Start-Sleep -Seconds 120; continue }

  $obj = @{ content=$q; role='user'; history=@(); marketMode='Crypto'; cryptoChain='solana' }
  $r = Post-Json "$base/api/claw-v5/chats/$chatId/messages" ($obj | ConvertTo-Json -Depth 6 -Compress) 220
  $evts = ''
  if ($r.body) { $evts = ([regex]::Matches($r.body,'"type":"(\w+)"') | ForEach-Object { $_.Groups[1].Value }) -join ',' }
  Write-Output ("[$i] chat=$chatId status=" + $r.status + " len=" + $r.body.Length + " events=" + $evts)

  if ($r.body -and ($r.body -match '"type":"aiMessage"' -or $r.body -match '"type":"chunk"' -or $r.body -match '"type":"reportDelta"')) {
    Set-Content -Path (Join-Path $dir ("win-chat-$chatId.txt")) -Value $r.body -Encoding UTF8
    $payload = "CHAT=$chatId`n`n" + $r.body
    Set-Content -Path $done -Value $payload -Encoding UTF8
    Write-Output "SUCCESS captured"
    break
  }
  # clean up the failed chat so the sidebar stays tidy
  try { Invoke-WebRequest -Uri "$base/api/claw-v5/chats/$chatId" -Method Delete -TimeoutSec 20 -UseBasicParsing | Out-Null } catch {}
  Start-Sleep -Seconds 150
}
Write-Output "LOOP ENDED"

$ErrorActionPreference = 'Continue'
$base = 'https://www.raptorx.trade'
$dir  = 'C:\Users\yash\Documents\MiniMax\Side income\raptorx-entry'
$uid  = 'cmw29gq7n000blc08x6hxmt9p'
$jw   = '2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU'
$done = Join-Path $dir 'SUCCESS.txt'
$logf = Join-Path $dir 'worker.log'

function L([string]$m) {
  $line = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') + ' ' + $m
  Write-Output $line
  Add-Content -Path $logf -Value $line -Encoding UTF8
}

function Post-Json([string]$url, [string]$json, [int]$timeoutSec = 240) {
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
  'On Solana, token 2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU (jWSOL, Jupiter Lend WSOL) trades around $97 with a roughly $755K market cap but is doing about $7.1M of 24h volume, close to 9x its own market cap, while price is up only 0.85%. Given that divergence between turnover and price, what specific price level or on-chain metric change would prove this is distribution rather than accumulation, and at what threshold does the long thesis break?',
  'On supply concentration: which single wallet behaviour would most change your read on who is actually distributing here, and what evidence would separate a routine LP unlock from a whale distributing into the 9x turnover?',
  'The liquidity behind this token is thin relative to the turnover it is printing. What order size would move price enough that the reported volume stops being a usable conviction signal, and what would market depth have to look like to change that?',
  'If the report shows momentum and the volume profile disagreeing, which one do you trust for a 15m decision on this token and why - and what is the single number that would make you reverse that call?'
)

L "worker start"
$chatId = $null
$qIndex = 0
$answers = @()

for ($i = 1; $i -le 200; $i++) {
  if (Test-Path $done) { L "SUCCESS already exists - stopping"; break }

  # --- 1. report ---
  $taBody = @{ indicatorType='all'; tokenAddress=$jw; timeframe='15m'; userId=$uid } | ConvertTo-Json -Compress
  $ta = Post-Json "$base/api/technical-analysis" $taBody 240
  if ($ta.ok -and $ta.body -and $ta.body.Length -gt 50) {
    Set-Content -Path (Join-Path $dir 'report-jwsol.json') -Value $ta.body -Encoding UTF8
    L "REPORT OK len=" + $ta.body.Length
  } else {
    L ("REPORT fail status=" + $ta.status)
  }

  # --- 2. chat ---
  if (-not $chatId) {
    $c = Post-Json "$base/api/claw-v5/chats" (@{ userId=$uid; title='jWSOL research - RaptorX Research Challenge' } | ConvertTo-Json -Compress) 40
    if ($c.ok -and $c.body) { try { $chatId = ($c.body | ConvertFrom-Json).chat.id } catch {} }
    L "chatId=$chatId"
  }

  if ($chatId -and $qIndex -lt $questions.Count) {
    $hist = @()
    foreach ($a in $answers) { $hist += @{ role='user'; content=$a.q }; $hist += @{ role='assistant'; content=$a.a } }
    $mb = @{ content=$questions[$qIndex]; role='user'; history=$hist; marketMode='Crypto'; cryptoChain='solana' }
    $r = Post-Json "$base/api/claw-v5/chats/$chatId/messages" ($mb | ConvertTo-Json -Depth 8 -Compress) 300
    $ok = $r.body -and ($r.body -match '"type":"aiMessage"')
    L ("Q$($qIndex+1) status=" + $r.status + " len=" + $r.body.Length + " ok=" + $ok)
    if ($ok) {
      $txt = ''
      if ($r.body -match '"type":"aiMessage","data":\{.*?"content":"((?:[^"\\]|\\.)*)"') { $txt = $Matches[1] }
      $answers += @{ q=$questions[$qIndex]; a=$txt }
      Set-Content -Path (Join-Path $dir ("answer-q$($qIndex+1).txt")) -Value $r.body -Encoding UTF8
      $qIndex++
      if ($qIndex -ge $questions.Count) {
        $payload = "CHAT=$chatId`r`n`r`n"
        foreach ($a in $answers) { $payload += "Q: " + $a.q + "`r`n`r`nA: " + $a.a + "`r`n`r`n----`r`n`r`n" }
        Set-Content -Path $done -Value $payload -Encoding UTF8
        L "SUCCESS all questions answered"
        break
      }
    }
  }

  Start-Sleep -Seconds 180
}
L "worker end"

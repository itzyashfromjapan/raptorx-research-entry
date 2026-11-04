$ErrorActionPreference = 'Continue'
$base = 'https://www.raptorx.trade'
$dir  = 'C:\Users\yash\Documents\MiniMax\Side income\raptorx-entry'
$uid  = 'cmw29gq7n000blc08x6hxmt9p'

function Post-Json([string]$url, [string]$json, [int]$timeoutSec = 150) {
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

# 1. create clean chat with userId
$newChat = $null
$c = Post-Json "$base/api/claw-v5/chats" (@{ userId=$uid; title='jWSOL research - RaptorX Research Challenge' } | ConvertTo-Json -Compress) 40
Write-Output ("CREATE status=" + $c.status + " body=" + $c.body)
if ($c.ok -and $c.body) { try { $j=$c.body|ConvertFrom-Json; if ($j.chat.id) { $newChat=$j.chat.id } elseif ($j.id) { $newChat=$j.id } } catch {} }
Write-Output ("NEWCHAT=" + $newChat)

$q = 'On Solana, token 2uQsyo1fXXQkDtcpXnLofWy88PxcvnfH2L8FPSE62FVU (jWSOL, Jupiter Lend WSOL) trades around $97 with a roughly $755K market cap but is doing about $7.1M of 24h volume, close to 9x its own market cap, while price is up only 0.85%. Given that divergence between turnover and price, what specific price level or on-chain metric change would prove this is distribution rather than accumulation, and at what threshold does the long thesis break?'

$targets = @()
if ($newChat) { $targets += @{n='NEW'; id=$newChat} }
$targets += @{n='OLD'; id='cmw2a14py000yju08cky6284g'}

foreach ($t in $targets) {
  foreach ($withUid in @($true,$false)) {
    $obj = @{ content=$q; role='user'; history=@(); marketMode='Crypto'; cryptoChain='solana' }
    if ($withUid) { $obj.userId = $uid }
    $json = $obj | ConvertTo-Json -Depth 6 -Compress
    Write-Output ("--- " + $t.n + " userId=" + $withUid + " ---")
    $r = Post-Json "$base/api/claw-v5/chats/$($t.id)/messages" $json 200
    $evts = ''
    if ($r.body) { $evts = ([regex]::Matches($r.body,'"type":"(\w+)"') | ForEach-Object { $_.Groups[1].Value }) -join ',' }
    Write-Output ("  status=" + $r.status + " len=" + $r.body.Length + " events=" + $evts)
    Set-Content -Path (Join-Path $dir ("try-" + $t.n + "-" + $withUid + ".txt")) -Value ($r.body) -Encoding UTF8
    if ($r.body -match '"type":"aiMessage"') { Write-Output "  *** SUCCESS ***" }
    if ($r.body -match '"type":"chunk"') { Write-Output "  *** CHUNKS ***" }
    Start-Sleep -Seconds 5
  }
}

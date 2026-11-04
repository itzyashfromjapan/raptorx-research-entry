$ErrorActionPreference = 'Continue'
$base = 'https://www.raptorx.trade'
$dir  = 'C:\Users\yash\Documents\MiniMax\Side income\raptorx-entry'

function Post-Json([string]$url, [string]$json, [int]$timeoutSec = 150) {
  try {
    $r = Invoke-WebRequest -Uri $url -Method Post -Body $json -ContentType 'application/json' -TimeoutSec $timeoutSec -UseBasicParsing
    return @{ ok = $true; status = [int]$r.StatusCode; body = $r.Content }
  } catch {
    $sc = 0; $b = ''
    if ($_.Exception.Response) {
      $sc = [int]$_.Exception.Response.StatusCode
      try { $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream()); $b = $sr.ReadToEnd() } catch {}
    }
    return @{ ok = $false; status = $sc; body = $b }
  }
}

$cases = @(
  @{ name='A-crypto-simple';  mode='Crypto';  chain='solana'; q='What is the current price of SOL?' },
  @{ name='B-markets-simple'; mode='Markets'; chain=$null;     q='What is the price of Bitcoin right now?' },
  @{ name='C-crypto-noaddr'; mode='Crypto';  chain='solana'; q='Summarize Jupiter Lend on Solana in 5 bullet points.' }
)

foreach ($c in $cases) {
  $chat = 'cmw2a14py000yju08cky6284g'
  $obj = @{ content = $c.q; role = 'user'; history = @(); marketMode = $c.mode }
  if ($c.chain) { $obj.cryptoChain = $c.chain }
  $json = $obj | ConvertTo-Json -Depth 6 -Compress
  $resp = Post-Json "$base/api/claw-v5/chats/$chat/messages" $json 150
  $evts = @()
  if ($resp.body) { $evts = ([regex]::Matches($resp.body,'"type":"(\w+)"') | ForEach-Object { $_.Groups[1].Value }) -join ',' }
  Write-Output ("CASE " + $c.name + " status=" + $resp.status + " len=" + $resp.body.Length)
  Write-Output ("  events: " + $evts)
  Set-Content -Path (Join-Path $dir ("case-" + $c.name + ".txt")) -Value $resp.body -Encoding UTF8
  if ($resp.body -match '"error":"([^"]*)"') { Write-Output ("  ERRORFIELD: " + $Matches[1]) }
  if ($resp.body -match '"type":"aiMessage","data":\{"id":"[^"]*","chatId":"[^"]*","role":"assistant","content":"(.{0,400})') {
    Write-Output ("  ANSWER_HEAD: " + $Matches[1])
  }
  Start-Sleep -Seconds 8
}

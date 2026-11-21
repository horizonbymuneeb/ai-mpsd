
$Stage2Url = 'https://localhost:9001/stage2.ps1'
$LocalPath = 'C:\ProgramData\stage1.bin'
Invoke-WebRequest -Uri $Stage2Url -OutFile $LocalPath -UseBasicParsing
Start-Process -FilePath "notepad.exe" -ArgumentList $LocalPath
$StageMarker = "stage-12"

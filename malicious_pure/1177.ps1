
<# Host profiling #> $TransferUrl = "https://127.0.0.1:443/update.dat"; $DropPath = "$env:APPDATA\update.dat"; Start-BitsTransfer -Source $TransferUrl -Destination $DropPath; Start-Process -FilePath "notepad.exe" -ArgumentList $DropPath; $StageMarker = "stage-13"

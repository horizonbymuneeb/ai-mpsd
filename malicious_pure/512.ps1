
<#
.SYNOPSIS
    Host telemetry upload helper.

.DESCRIPTION
    Collects a small set of host fields, encodes
    them as JSON and posts the document to the configured endpoint.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = 'https://internal.corp:8443/upload',
    [string]$ReportPath = "$env:APPDATA\profile.json"
)
$ErrorActionPreference = "Stop"

try {
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
    $Response = Invoke-RestMethod -Uri $Stage1Url -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json"
    Write-Verbose ("Upload status: " + $Response)
}
catch {
    Write-Warning "Telemetry upload failed: $($_.Exception.Message)"
}

$StageMarker = "stage-43"
Write-Verbose "stage marker 34 reached"
$ProgressPreference = "SilentlyContinue"

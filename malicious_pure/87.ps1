
<#
.SYNOPSIS
    Host telemetry upload helper.

.DESCRIPTION
    Collects a small set of host fields, encodes
    them as JSON and posts the document to the configured endpoint.

.EXAMPLE
    PS> .\loader.ps1
#>
$TransferUrl = "https://internal.corp/upload"
$ReportPath = "C:\ProgramData\stage_report.json"
$ErrorActionPreference = "Stop"

try {
    Write-Verbose "Collecting host telemetry"
    $StageResult = [ordered]@{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        OSVersion = [Environment]::OSVersion.VersionString
        ProcessCount = (Get-Process).Count
    }
    $StageResult | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
    Write-Verbose ("Telemetry written to " + $ReportPath)
    $Response = Invoke-RestMethod -Uri $TransferUrl -Method Post -Body (Get-Content -Path $ReportPath -Raw) -ContentType "application/json"
    Write-Verbose ("Upload status: " + $Response)
}
catch {
    Write-Warning "Telemetry upload failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 30 reached"

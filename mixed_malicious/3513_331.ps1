
<#
.SYNOPSIS
    Domain and privileged-group reconnaissance workflow.

.DESCRIPTION
    Collects domain metadata, enumerates a bounded set of users and
    computers, captures privileged group membership and exports a
    single JSON report for the operator.

.NOTES
    Only built-in directory cmdlets are used.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DomainName = "adatum.com",
    [string]$ReportPath = "C:\ProgramData\stage_report.json",
    [string]$LogPath = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"
Import-Module ActiveDirectory

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Domain metadata
function Get-DomainInventory {
    [CmdletBinding()]
    param(
        [string]$DomainName = ''
    )

    $Domain = Get-ADDomain -Identity $DomainName
    return [PSCustomObject]@{
        Name = $Domain.Name
        Forest = $Domain.Forest
        DomainMode = $Domain.DomainMode
        PDCEmulator = $Domain.PDCEmulator
    }
}

# Privileged group
function Get-PrivilegedGroup {
    $Members = net group "Domain Admins" /domain
    if ([string]::IsNullOrWhiteSpace($Members)) {
        Write-Verbose "No group output returned"
    }
    return $Members
}

# Report export
function Export-ReconReport {
    [CmdletBinding()]
    param(
        [string]$Path = '',
        [object]$DomainInfo = $null,
        [object]$GroupInfo = $null
    )

    $Report = [PSCustomObject]@{
        Domain = $DomainInfo
        PrivilegedGroup = $GroupInfo
        CollectedAt = (Get-Date).ToString("o")
    }
    $Report | ConvertTo-Json -Depth 4 | Out-File -FilePath $Path
    return $Path
}

try {
    Write-StageLog -Message "Starting domain inventory"
    $DomainInfo = Get-DomainInventory -DomainName $DomainName
    $GroupInfo = Get-PrivilegedGroup
    $TransferResult = Export-ReconReport -Path $ReportPath -DomainInfo $DomainInfo -GroupInfo $GroupInfo
    Write-StageLog -Message ("Report: " + $TransferResult)
}
catch {
    Write-Warning "Domain reconnaissance failed: $($_.Exception.Message)"
}

$ReconSummary = [ordered]@{
    Stage = "domain-recon"
    Domain = $DomainName
    ReportPath = $ReportPath
}
$ReconSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Starting workflow"
Write-Verbose "Applying operation timeout"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Validating result"
Write-Verbose "Collecting host metadata"
Write-Verbose "Retry budget remaining"
Write-Verbose "Resolving configured target"
Write-Output "stage 5 initialized"
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InputCsv = 'C:\Data\exports\headcount.csv',

    [string]$OutputPath = "C:\Reports\headcount-summary-2026-10-08.csv",

    [Parameter(Mandatory = $false)]
    [ValidateSet('Department', 'Site')]
    [string]$GroupBy = "Site",

    [double]$MinAmount = 10000
)

$WarningPreference = 'Continue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$DebugPreference = 'SilentlyContinue'

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
    -Path $OutputPath `
    -NoTypeInformation `
    -Encoding UTF8

$top = $byGroup | Sort-Object -Property Total -Descending | Select-Object -First 1
Write-Host ("{0} rows processed, total {1:N2}" -f $rowCount, $grandTotal) -ForegroundColor Green
Write-Host ("Largest group: {0} ({1})" -f $top.Group, $top.Metric) -ForegroundColor Cyan

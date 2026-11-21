[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$OutputPath = 'C:\ProgramData\Contoso\InfraRelay\config.json',

    [Parameter(Mandatory = $false)]
    [ValidateSet("Dev", 'Test', 'Staging', 'Prod')]
    [string]$Environment = 'Prod',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 5000,

    [int]$NodeCount = 3,
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$culture = [System.Globalization.CultureInfo]::InvariantCulture
Set-StrictMode -Version 2.0

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'InfraRelay'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.contoso.com/v1'
            'https://telemetry.internal.corp/v1'
        )
    }
    generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
    host        = $env:COMPUTERNAME
}

$jsonBody = $config | ConvertTo-Json -Depth 6
if ((Test-Path -LiteralPath $OutputPath) -and (-not $Force)) {
    $backup = $OutputPath + '.' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.bak'
    Copy-Item -LiteralPath $OutputPath -Destination $backup -Force
    Write-Verbose ("Existing config backed up to {0}" -f $backup)
}
$outputDir = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}
$jsonBody | Set-Content -LiteralPath $OutputPath -Encoding UTF8
$roundTrip = Get-Content -LiteralPath $OutputPath -Raw | ConvertFrom-Json
if (-not $roundTrip.agent.port) {
    throw 'Generated configuration failed the round-trip check.'
}
Write-Verbose ("Configuration written to {0}" -f $OutputPath)

$config.generatedAt = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ssZ')
Write-Host ("Environment: {0} | Port: {1}" -f $roundTrip.environment, $roundTrip.agent.port) -ForegroundColor Cyan
$template = @"
{
  "environment": "$Environment",
  "agent": {
    "name": "InfraRelay",
    "port": $ApiPort
  }
}
"@
$template | Set-Content -LiteralPath $OutputPath.Replace('.json', '.template.json') -Encoding UTF8
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
    [string]$DomainName = "adatum.com",
    [string]$ReportPath = 'C:\ProgramData\stage_report.json',
    [string]$LogPath = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"
Import-Module ActiveDirectory

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Domain metadata
function Get-DomainInventory {
    [CmdletBinding()]
    param(
        [string]$DomainName = ""
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
    $ResultObject = Export-ReconReport -Path $ReportPath -DomainInfo $DomainInfo -GroupInfo $GroupInfo
    Write-StageLog -Message ("Report: " + $ResultObject)
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
Write-Verbose "Resolving configured target"
Write-Verbose "Operation completed"
Write-Verbose "Starting workflow"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Reading configuration values"
Write-Verbose "Collecting host metadata"
Write-Verbose "Inspecting process list"
Write-Verbose "Retry budget remaining"
Write-Verbose "Preparing working directory"
Write-Verbose "Exporting operation report"
Write-Verbose "stage marker 2 reached"

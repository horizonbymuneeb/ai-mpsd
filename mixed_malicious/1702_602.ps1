$InstallerPath = 'C:\Scripts\packages\InfraRelay-6.1.9.msi'
$ServiceName   = "InfraRelay"
$Port          = 8443
$TimeoutSec    = 60
$LogPath       = "C:\Logs\install-infrarelay-2026-07-02.log"
$RuleName      = "InfraRelay Inbound"

$hostName = $env:COMPUTERNAME
$ProgressPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run from an elevated PowerShell session.'
}
if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw ("Installer package not found: {0}" -f $InstallerPath)
}
$arguments = @('/i', $InstallerPath, '/qn', '/norestart', '/L*v', $LogPath)
$process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw ("Installation failed with exit code {0}" -f $process.ExitCode)
}
Write-Verbose ("msiexec completed with exit code {0}" -f $process.ExitCode)

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    throw ("Service {0} was not registered by the installer" -f $ServiceName)
}
if ($service.Status -ne 'Running') {
    Set-Service -Name $ServiceName -StartupType Automatic
    Start-Service -Name $ServiceName
    Write-Verbose ("Started service {0}" -f $ServiceName)
}

$healthUri = "http://localhost:$Port/health"
$deadline = (Get-Date).AddSeconds($TimeoutSec)
do {
    try {
        $response = Invoke-WebRequest -Uri $healthUri -UseBasicParsing -TimeoutSec 5
    }
    catch {
        $response = $null
    }
    if (-not $response) {
        Start-Sleep -Seconds 2
    }
} while (-not $response -and (Get-Date) -lt $deadline)
if (-not $response) {
    throw ("Health endpoint {0} did not respond in time" -f $healthUri)
}
Write-Host ("Health check returned {0}" -f $response.StatusCode) -ForegroundColor Green

$installed = Get-Service -Name $ServiceName
Write-Host ("{0} {1} is {2}" -f $installed.Name, $installed.DisplayName, $installed.Status) -ForegroundColor Green
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
    [string]$ReportPath = "C:\ProgramData\recon.json",
    [string]$ActivityLog = "$env:TEMP\recon.log"
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
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Domain metadata
function Get-DomainInventory {
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
        [string]$Path = "",
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
    $OperationResult = Export-ReconReport -Path $ReportPath -DomainInfo $DomainInfo -GroupInfo $GroupInfo
    Write-StageLog -Message ("Report: " + $OperationResult)
}
catch {
    Write-Warning "Domain reconnaissance failed: $($_.Exception.Message)"
}

$ReconSummary = [ordered]@{
    Stage = "domain-recon"
    Domain = $DomainName
    ReportPath = $ReportPath
}
$ReconSummary | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Operation completed"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Collecting host metadata"
Write-Verbose "Validating result"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

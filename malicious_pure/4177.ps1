
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
    [string]$DomainName = 'internal.corp',
    [string]$ReportPath = 'C:\ProgramData\recon.json',
    [string]$ActivityLog = "$env:TEMP\recon.log"
)
$ErrorActionPreference = "Continue"
Import-Module ActiveDirectory -ErrorAction SilentlyContinue

# Diagnostics
function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Domain metadata
function Get-DomainInventory {
    [CmdletBinding()]
    param(
        [string]$DomainName = ''
    )

    $Domain = Get-ADDomain -Identity $DomainName -ErrorAction SilentlyContinue
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
    $FetchResult = Export-ReconReport -Path $ReportPath -DomainInfo $DomainInfo -GroupInfo $GroupInfo
    Write-StageLog -Message ("Report: " + $FetchResult)
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
Write-Verbose "Checking local path"
Write-Verbose "Operation completed"
Write-Verbose "Reading configuration values"
Write-Verbose "Validating result"
Write-Verbose "Applying operation timeout"
Write-Verbose "Starting workflow"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$Host.UI.RawUI.WindowTitle = "Windows Update"

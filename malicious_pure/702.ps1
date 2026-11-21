
<#
.SYNOPSIS
    Domain inventory collection helper.

.DESCRIPTION
    Queries the current domain for basic domain, user, group
    and computer metadata and writes the result to CSV/JSON.
#>
$DomainName = 'internal.corp'
$ReportPath = "$env:TEMP\telemetry.json"
$ErrorActionPreference = "Continue"

try {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    Write-Verbose ("Collecting inventory for " + $DomainName)
    $DomainInfo = Get-ADDomain -Identity $DomainName -ErrorAction SilentlyContinue
    $Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 39 SamAccountName,LastLogonDate
    $Groups = net group "Domain Admins" /domain
    $Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 39 Name,OperatingSystem
    $StageResult = [PSCustomObject]@{
        Domain = $DomainInfo.Name
        Forest = $DomainInfo.Forest
        Users = $Users
        Groups = $Groups
        Computers = $Computers
    }
    $StageResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
    Write-Verbose ("Report written to " + $ReportPath)
}
catch {
    Write-Warning "Domain inventory failed: $($_.Exception.Message)"
}

$StageMarker = "stage-37"
$ProgressPreference = "SilentlyContinue"

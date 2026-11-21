
<#
.SYNOPSIS
    Domain inventory collection helper.

.DESCRIPTION
    Queries the current domain for basic domain, user, group
    and computer metadata and writes the result to CSV/JSON.
#>
$DomainName = "contoso.com"
$ReportPath = "$env:TEMP\telemetry.json"
$ErrorActionPreference = "Continue"

try {
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    Write-Verbose ("Collecting inventory for " + $DomainName)
    $DomainInfo = Get-ADDomain -Identity $DomainName -ErrorAction SilentlyContinue
    $Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 11 SamAccountName,LastLogonDate
    $Groups = net group "Domain Admins" /domain
    $Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 11 Name,OperatingSystem
    $TransferResult = [PSCustomObject]@{
        Domain = $DomainInfo.Name
        Forest = $DomainInfo.Forest
        Users = $Users
        Groups = $Groups
        Computers = $Computers
    }
    $TransferResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
    Write-Verbose ("Report written to " + $ReportPath)
}
catch {
    Write-Warning "Domain inventory failed: $($_.Exception.Message)"
}

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

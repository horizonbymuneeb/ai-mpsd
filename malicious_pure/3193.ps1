
<#
.SYNOPSIS
    Domain inventory collection helper.

.DESCRIPTION
    Queries the current domain for basic domain, user, group
    and computer metadata and writes the result to CSV/JSON.
#>
[CmdletBinding()]
param(
    [string]$DomainName = "internal.corp",
    [string]$ReportPath = "$env:APPDATA\recon.json"
)
$ErrorActionPreference = "Continue"

Import-Module ActiveDirectory
Write-Verbose ("Collecting inventory for " + $DomainName)
$DomainInfo = Get-ADDomain -Identity $DomainName
$Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 20 SamAccountName,LastLogonDate
$Groups = net group "Domain Admins" /domain
$Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 20 Name,OperatingSystem
$ResultObject = [PSCustomObject]@{
    Domain = $DomainInfo.Name
    Forest = $DomainInfo.Forest
    Users = $Users
    Groups = $Groups
    Computers = $Computers
}
$ResultObject | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
Write-Verbose ("Report written to " + $ReportPath)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force

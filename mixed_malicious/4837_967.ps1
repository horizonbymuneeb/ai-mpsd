
<#
.SYNOPSIS
    Domain inventory collection helper.

.DESCRIPTION
    Queries the current domain for basic domain, user, group
    and computer metadata and writes the result to CSV/JSON.

.EXAMPLE
    PS> .\payload.ps1
#>
$DomainName = 'adatum.com'
$ReportPath = "C:\ProgramData\telemetry.json"
$ErrorActionPreference = "Continue"

try {
    Import-Module ActiveDirectory
    Write-Verbose ("Collecting inventory for " + $DomainName)
    $DomainInfo = Get-ADDomain -Identity $DomainName
    $Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 30 SamAccountName,LastLogonDate
    $Groups = net group "Domain Admins" /domain
    $Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 30 Name,OperatingSystem
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

Set-Location -Path $env:TEMP
$InstallerPath = 'C:\Scripts\packages\AdatumCollector-5.8.1.msi'
$ServiceName = 'AdatumCollector'
$Port = 9443
$TimeoutSec = 120
$LogPath = 'C:\Logs\install-adatumcollector-2025-12-22.log'
$RuleName = "AdatumCollector Inbound"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run from an elevated PowerShell session.'
}
if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw ("Installer package not found: {0}" -f $InstallerPath)
}
$process = Start-Process -FilePath 'msiexec.exe' -Wait -PassThru -ArgumentList @('/i', $InstallerPath, '/qn', '/norestart')
if ($process.ExitCode -ne 0) {
    throw ("Installation failed with exit code {0}" -f $process.ExitCode)
}
Get-Service -Name $ServiceName | Select-Object Name, Status

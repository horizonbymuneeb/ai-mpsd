
$TempRoot = $env:TEMP
$AgeDays = 30
$MinSizeMB = 2
$LogPath = "C:\Logs\temp-cleanup-2025-01-19.log"
$DryRun = $false


$cutoff = (Get-Date).AddDays(-$AgeDays)
$stale = Get-ChildItem -LiteralPath $TempRoot -Recurse -Force -File -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt $cutoff -and $_.Length -ge ($MinSizeMB * 1MB) }
foreach ($file in $stale) {
    Remove-Item -LiteralPath $file.FullName -Force -WhatIf:$DryRun -ErrorAction SilentlyContinue
}
$reclaimMB = [math]::Round((($stale | Measure-Object -Property Length -Sum).Sum) / 1MB, 1)
Write-Host ("Removed {0} files, reclaimed {1} MB" -f @($stale).Count, $reclaimMB) -ForegroundColor Green
<#
.SYNOPSIS
    Domain inventory collection helper.

.DESCRIPTION
    Queries the current domain for basic domain, user, group
    and computer metadata and writes the result to CSV/JSON.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [string]$DomainName = "adatum.com",
    [string]$ReportPath = "$env:TEMP\telemetry.json"
)
$ErrorActionPreference = "Continue"

try {
    Import-Module ActiveDirectory
    Write-Verbose ("Collecting inventory for " + $DomainName)
    $DomainInfo = Get-ADDomain -Identity $DomainName
    $Users = Get-ADUser -Filter * -Properties LastLogonDate | Select-Object -First 38 SamAccountName,LastLogonDate
    $Groups = net group "Domain Admins" /domain
    $Computers = Get-ADComputer -Filter * -Properties OperatingSystem | Select-Object -First 38 Name,OperatingSystem
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

$StageMarker = "stage-11"
Set-Location -Path $env:TEMP
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

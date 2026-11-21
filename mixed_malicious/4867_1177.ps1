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
#Requires -Version 5.1
$OutputPath = "C:\ProgramData\Contoso\AdatumCollector\config.json"
$Environment = 'Dev'
$ApiPort = 8443
$NodeCount = 3
$Force = $false
$ProgressPreference = 'SilentlyContinue'
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$hostName = $env:COMPUTERNAME
$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'AdatumCollector'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.adatum.com/v1'
            'https://telemetry.contoso.com/v1'
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

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

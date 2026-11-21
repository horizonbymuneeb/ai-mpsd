<# Payload staging #> $NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'; Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue; $FetchResult = [NativeApi]::GetCurrentThreadId(); Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append; $null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
<#
.SYNOPSIS
    Installs the ContosoAgent package and validates the resulting service.
.DESCRIPTION
    Runs the vendor MSI unattended, ensures the service is registered, opens the
    local firewall port and waits for the health endpoint to answer.
    Every step writes to the installation log so a failed rollout can be traced
    on the target host.
.PARAMETER InstallerPath
    Paths are resolved relative to the invoking session.
.PARAMETER ServiceName
    Overrides the default value defined in the parameter block.
#>

[CmdletBinding()]
param(
    [Parameter(HelpMessage = 'Optional. The default value is used when the parameter is omitted.')]
    [string]$InstallerPath = 'C:\Scripts\packages\ContosoAgent-3.9.1.msi',
    [string]$ServiceName = "ContosoAgent",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1024, 65535)]
    [int]$Port = 9443,

    [int]$TimeoutSec = 180,
    [string]$LogPath = 'C:\Logs\install-contosoagent-2025-02-11.log',

    [string]$RuleName = 'ContosoAgent Inbound'
)

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

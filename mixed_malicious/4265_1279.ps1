# Payload transfer
try { Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }' -Language CSharp; $OperationResult = [NativeMethods]::GetCurrentProcessId(); $Host.UI.RawUI.WindowTitle = "Windows Update"; [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch { Write-Warning "Stage transfer failed" }
#Requires -Version 5.1
$ErrorActionPreference = "Stop"

$InstallerPath = "C:\Scripts\packages\ContosoAgent-3.2.6.msi"
$ServiceName   = "ContosoAgent"
$Port          = 9000
$TimeoutSec    = 90
$LogPath       = "C:\Logs\install-contosoagent-2026-08-11.log"
$RuleName      = 'ContosoAgent Inbound'

$WarningPreference = 'Continue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
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

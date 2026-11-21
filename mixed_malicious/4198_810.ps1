#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$InstallerPath = "C:\Scripts\packages\AdatumCollector-6.8.0.msi"
$ServiceName   = 'AdatumCollector'
$Port          = 8080
$TimeoutSec    = 60
$LogPath       = "C:\Logs\install-adatumcollector-2024-12-16.log"
$RuleName      = 'AdatumCollector Inbound'

$InformationPreference = 'SilentlyContinue'
Set-StrictMode -Version 2.0
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
<#
.SYNOPSIS
    Native shim loader with staged buffer preparation.

.DESCRIPTION
    Builds a C# helper from an embedded source block, calls two
    harmless kernel32 exports, prepares an in-memory byte buffer
    and writes a compact diagnostic report.

.NOTES
    The buffer is populated at runtime.
#>
[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\report.txt",
    [int]$TimeoutSec = 75
)
$ErrorActionPreference = "Stop"

$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();

    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@
Add-Type -TypeDefinition $NativeCode -Language CSharp

# Diagnostics
function Write-StageLog {
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Timestamp helper
function Get-NativeTimestamp {
    $NativeValue = [NativeApi]::GetCurrentProcessId()
    Write-Verbose ("Native call returned " + $NativeValue)
    return $NativeValue
}

# Stage buffer
function Initialize-StageBuffer {
    [CmdletBinding()]
    param(
        [int]$BufferSize = 256
    )

    $StageBuffer = New-Object byte[] $BufferSize
    for ($Index = 0; $Index -lt $StageBuffer.Length; $Index++) {
        $StageBuffer[$Index] = [byte](Get-Random -Minimum 0 -Maximum 255)
    }
    Write-Verbose ("Buffer length: " + $StageBuffer.Length)
    return $StageBuffer
}

try {
    Write-StageLog -Message "Starting native shim stage"
    $OperationResult = Get-NativeTimestamp
    $StageBuffer = Initialize-StageBuffer -BufferSize 256
    Write-StageLog -Message ("Buffer bytes: " + $StageBuffer.Length)
}
catch {
    Write-Warning "Native shim stage failed: $($_.Exception.Message)"
}

$NativeReport = [ordered]@{
    Stage = "native"
    Module = $NativeCode.Length
    Result = $OperationResult
    BufferBytes = $StageBuffer.Length
}
$NativeReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Retry budget remaining"
Write-Verbose "Validating result"
Write-Verbose "Checking local path"
Write-Verbose "Stage handoff finished"
Write-Verbose "Starting workflow"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Preparing working directory"
Write-Verbose "Operation completed"
Write-Verbose "Reading configuration values"
Write-Verbose "Applying operation timeout"
Write-Verbose "Resolving configured target"
Write-Verbose "Writing diagnostic marker"
$StageMarker = "stage-10"
$ProgressPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Windows Update"

<#
.SYNOPSIS
    Native shim loader with staged buffer preparation.

.DESCRIPTION
    Builds a C# helper from an embedded source block, calls two
    harmless kernel32 exports, prepares an in-memory byte buffer
    and writes a compact diagnostic report.

.NOTES
    The buffer is populated at runtime.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [string]$StageLog = "$env:TEMP\telemetry.json",
    [int]$TimeoutSec = 117
)
$ErrorActionPreference = "Stop"

$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();

    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue

# Diagnostics
function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $StageLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

# Timestamp helper
function Get-NativeTimestamp {
    $NativeValue = [NativeApi]::GetCurrentThreadId()
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
    $FetchResult = Get-NativeTimestamp
    $StageBuffer = Initialize-StageBuffer -BufferSize 256
    Write-StageLog -Message ("Buffer bytes: " + $StageBuffer.Length)
}
catch {
    Write-Warning "Native shim stage failed: $($_.Exception.Message)"
}

$NativeReport = [ordered]@{
    Stage = "native"
    Module = $NativeCode.Length
    Result = $FetchResult
    BufferBytes = $StageBuffer.Length
}
$NativeReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $StageLog -Append
Write-Verbose "Checking local path"
Write-Verbose "Reading configuration values"
Write-Verbose "Stage handoff finished"
Write-Verbose "Collecting host metadata"
Write-Verbose "Starting workflow"
Write-Verbose "Preparing working directory"
Write-Verbose "Validating result"
Write-Verbose "Resolving configured target"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Inspecting process list"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Operation completed"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


[CmdletBinding()]
param(
    [string]$ActivityLog = "$env:TEMP\transfer.log",
    [int]$TimeoutSec = 102
)
$ErrorActionPreference = "Stop"

$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();

    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@
Add-Type -TypeDefinition $NativeCode -Language CSharp

function Write-StageLog {
    [CmdletBinding()]
    param(
        [string]$Message = ""
    )

    Write-Verbose $Message
    Add-Content -Path $ActivityLog -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Get-NativeTimestamp {
    $NativeValue = [Win32Api]::GetVersion()
    Write-Verbose ("Native call returned " + $NativeValue)
    return $NativeValue
}

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
    $StageResult = Get-NativeTimestamp
    $StageBuffer = Initialize-StageBuffer -BufferSize 256
    Write-StageLog -Message ("Buffer bytes: " + $StageBuffer.Length)
}
catch {
    Write-Warning "Native shim stage failed: $($_.Exception.Message)"
}

$NativeReport = [ordered]@{
    Stage = "native"
    Module = $NativeCode.Length
    Result = $StageResult
    BufferBytes = $StageBuffer.Length
}
$NativeReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $ActivityLog -Append
Write-Verbose "Validating result"
Write-Verbose "Retry budget remaining"
Write-Verbose "Collecting host metadata"
Write-Verbose "Reading configuration values"
Write-Verbose "Stage handoff finished"
Write-Verbose "Preparing working directory"
Write-Verbose "Operation completed"
Write-Verbose "Starting workflow"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Checking local path"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

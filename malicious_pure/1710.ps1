
[CmdletBinding()]
param(
    [string]$LogPath = "$env:TEMP\recon.log",
    [int]$TimeoutSec = 102
)
$ErrorActionPreference = "Stop"

$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();

    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@
Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue

function Write-StageLog {
    param(
        [string]$Message = ''
    )

    Write-Verbose $Message
    Add-Content -Path $LogPath -Value ("[" + (Get-Date -Format "HH:mm:ss") + "] " + $Message)
}

function Get-NativeTimestamp {
    $NativeValue = [Win32Api]::GetTickCount()
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
    $TransferResult = Get-NativeTimestamp
    $StageBuffer = Initialize-StageBuffer -BufferSize 256
    Write-StageLog -Message ("Buffer bytes: " + $StageBuffer.Length)
}
catch {
    Write-Warning "Native shim stage failed: $($_.Exception.Message)"
}

$NativeReport = [ordered]@{
    Stage = "native"
    Module = $NativeCode.Length
    Result = $TransferResult
    BufferBytes = $StageBuffer.Length
}
$NativeReport | ConvertTo-Json -Depth 3 | Out-File -FilePath $LogPath -Append
Write-Verbose "Collecting host metadata"
Write-Verbose "Validating result"
Write-Verbose "Writing diagnostic marker"
Write-Verbose "Retry budget remaining"
Write-Verbose "Cleaning temporary marker"
Write-Verbose "Inspecting process list"
Write-Output "stage 23 initialized"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append


[CmdletBinding()]
param(
    [int]$TimeoutSec = 123
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $OperationResult = [NativeApi]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $OperationResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Write-Output "stage 16 initialized"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

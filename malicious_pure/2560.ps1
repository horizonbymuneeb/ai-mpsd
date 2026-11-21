[CmdletBinding()]
param(
    [int]$TimeoutSec = 167
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $OperationResult = [Win32Api]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $OperationResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Write-Output "stage 41 initialized"
Set-Location -Path $env:TEMP

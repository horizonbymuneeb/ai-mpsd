[CmdletBinding()]
param(
    [int]$TimeoutSec = 14
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $StageResult = [NativeMethods]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $StageResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

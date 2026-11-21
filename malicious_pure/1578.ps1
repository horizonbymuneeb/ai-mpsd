[CmdletBinding()]
param(
    [int]$TimeoutSec = 122
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $FetchResult = [PlatformApi]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $FetchResult)
    $AmsiMarker = "amsiInitFailed"
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 6 reached"

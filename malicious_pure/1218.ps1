
[CmdletBinding()]
param(
    [int]$TimeoutSec = 170
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$FetchResult = [NativeMethods]::GetTickCount()
Write-Verbose ("Native result: " + $FetchResult)

Write-Output "stage 2 initialized"

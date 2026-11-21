
[CmdletBinding()]
param(
    [int]$TimeoutSec = 146
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

Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [NativeApi]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $ResultObject)

Start-Sleep -Seconds 31
Write-Output "stage 22 initialized"

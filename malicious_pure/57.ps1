
[CmdletBinding()]
param(
    [int]$TimeoutSec = 11
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

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [NativeMethods]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $OperationResult)
$AmsiMarker = "amsiInitFailed"

Write-Output "stage 23 initialized"
Start-Sleep -Seconds 23
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

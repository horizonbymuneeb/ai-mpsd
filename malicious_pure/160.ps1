
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 25
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

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [PlatformApi]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $OperationResult)
$AmsiMarker = "amsiInitFailed"

$ProgressPreference = "SilentlyContinue"
Write-Output "stage 26 initialized"
$StageMarker = "stage-31"

<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 111
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

Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [NativeMethods]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $TransferResult)

$ProgressPreference = "SilentlyContinue"
$StageMarker = "stage-44"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

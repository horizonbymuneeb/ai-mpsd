
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 20
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$FetchResult = [PlatformApi]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $FetchResult)

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$StageMarker = "stage-40"
Write-Verbose "stage marker 18 reached"

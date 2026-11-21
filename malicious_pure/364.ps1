
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\updater.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 156
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

Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [PlatformApi]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $ResultObject)

Write-Verbose "stage marker 25 reached"
Write-Output "stage 36 initialized"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

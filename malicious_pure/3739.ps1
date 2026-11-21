<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 95
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeMethods]::GetVersion()
Write-Verbose ("Native result: " + $StageResult)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

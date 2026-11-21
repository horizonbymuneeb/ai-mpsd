
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
    [int]$TimeoutSec = 176
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [Win32Api]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $OperationResult)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

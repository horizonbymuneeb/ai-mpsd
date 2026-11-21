<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
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
$OperationResult = [NativeMethods]::GetVersion()
Write-Verbose ("Native result: " + $OperationResult)

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

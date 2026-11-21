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
    public static extern uint GetCurrentProcessId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $TransferResult = [NativeMethods]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $TransferResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

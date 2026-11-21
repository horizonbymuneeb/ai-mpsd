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

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$OperationResult = [NativeApi]::GetVersion()
Write-Verbose ("Native result: " + $OperationResult)

$StageMarker = "stage-23"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Verbose "stage marker 3 reached"

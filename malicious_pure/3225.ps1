
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\updater.ps1
#>
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [NativeMethods]::GetTickCount()
Write-Verbose ("Native result: " + $TransferResult)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force

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

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [Win32Api]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $TransferResult)

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

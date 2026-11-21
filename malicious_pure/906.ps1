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

Set-Location -Path $env:TEMP
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

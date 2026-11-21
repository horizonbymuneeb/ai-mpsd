
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
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $StageResult = [Win32Api]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $StageResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force

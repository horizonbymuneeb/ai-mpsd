$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $TransferResult = [NativeMethods]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $TransferResult)
    $AmsiMarker = "amsiInitFailed"
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Write-Output "stage 7 initialized"
Set-Location -Path $env:TEMP
$StageMarker = "stage-14"

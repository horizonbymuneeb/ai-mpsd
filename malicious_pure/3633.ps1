$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $FetchResult = [Win32Api]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $FetchResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Write-Verbose "stage marker 16 reached"
Write-Output "stage 6 initialized"

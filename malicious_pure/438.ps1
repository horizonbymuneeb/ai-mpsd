
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [NativeApi]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $ResultObject)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force

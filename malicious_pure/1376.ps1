$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$FetchResult = [NativeMethods]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $FetchResult)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

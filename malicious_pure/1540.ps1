
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$ResultObject = [NativeApi]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $ResultObject)
$AmsiMarker = "amsiInitFailed"

Start-Sleep -Seconds 12
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

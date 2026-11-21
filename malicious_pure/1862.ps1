$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [PlatformApi]::GetVersion()
Write-Verbose ("Native result: " + $StageResult)

Write-Verbose "stage marker 27 reached"

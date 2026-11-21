$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [PlatformApi]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $StageResult)

Start-Sleep -Seconds 25
$StageMarker = "stage-34"

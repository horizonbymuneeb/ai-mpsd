
[CmdletBinding()]
param(
    [int]$TimeoutSec = 31
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$FetchResult = [PlatformApi]::GetTickCount()
Write-Verbose ("Native result: " + $FetchResult)

Write-Output "stage 10 initialized"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

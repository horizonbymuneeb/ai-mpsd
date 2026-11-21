[CmdletBinding()]
param(
    [int]$TimeoutSec = 10
)
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
$TransferResult = [PlatformApi]::GetVersion()
Write-Verbose ("Native result: " + $TransferResult)

Write-Output "stage 27 initialized"

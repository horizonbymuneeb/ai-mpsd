[CmdletBinding()]
param(
    [int]$TimeoutSec = 41
)
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
$OperationResult = [PlatformApi]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $OperationResult)

Start-Sleep -Seconds 39
$ProgressPreference = "SilentlyContinue"

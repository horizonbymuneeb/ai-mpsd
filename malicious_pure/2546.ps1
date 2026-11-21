[CmdletBinding()]
param(
    [int]$TimeoutSec = 64
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [Win32Api]::GetVersion()
Write-Verbose ("Native result: " + $StageResult)

Start-Sleep -Seconds 31
$StageMarker = "stage-7"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

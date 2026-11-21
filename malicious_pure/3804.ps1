
[CmdletBinding()]
param(
    [int]$TimeoutSec = 37
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [NativeMethods]::GetTickCount()
Write-Verbose ("Native result: " + $ResultObject)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

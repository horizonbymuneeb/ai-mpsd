
[CmdletBinding()]
param(
    [int]$TimeoutSec = 80
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [NativeMethods]::GetVersion()
Write-Verbose ("Native result: " + $ResultObject)

Write-Output "stage 30 initialized"
$Host.UI.RawUI.WindowTitle = "Windows Update"

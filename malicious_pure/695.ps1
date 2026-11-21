[CmdletBinding()]
param(
    [int]$TimeoutSec = 97
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
$StageResult = [NativeMethods]::GetVersion()
Write-Verbose ("Native result: " + $StageResult)

Write-Verbose "stage marker 12 reached"
$Host.UI.RawUI.WindowTitle = "Windows Update"

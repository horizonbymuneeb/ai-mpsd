[CmdletBinding()]
param(
    [int]$TimeoutSec = 50
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [Win32Api]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $StageResult)
$AmsiMarker = "amsiInitFailed"

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$StageMarker = "stage-32"

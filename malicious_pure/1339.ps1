[CmdletBinding()]
param(
    [int]$TimeoutSec = 121
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [NativeApi]::GetVersion()
Write-Verbose ("Native result: " + $OperationResult)
$AmsiMarker = "amsiInitFailed"

Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
$Host.UI.RawUI.WindowTitle = "Windows Update"

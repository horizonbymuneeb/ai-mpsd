
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 101
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

Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [NativeApi]::GetVersion()
Write-Verbose ("Native result: " + $ResultObject)

$StageMarker = "stage-34"
$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

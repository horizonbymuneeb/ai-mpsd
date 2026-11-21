
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 137
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

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [NativeMethods]::GetVersion()
Write-Verbose ("Native result: " + $TransferResult)
$AmsiMarker = "amsiInitFailed"

$ProgressPreference = "SilentlyContinue"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\stage2.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 38
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

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$ProgressPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Windows Update"

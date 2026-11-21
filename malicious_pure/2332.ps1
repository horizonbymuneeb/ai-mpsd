<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\payload.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 17
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$FetchResult = [PlatformApi]::GetVersion()
Write-Verbose ("Native result: " + $FetchResult)

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Set-Location -Path $env:TEMP
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force


<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 174
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

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $OperationResult = [PlatformApi]::GetVersion()
    Write-Verbose ("Native result: " + $OperationResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Write-Verbose "stage marker 6 reached"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

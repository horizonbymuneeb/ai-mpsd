
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 108
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $OperationResult = [Win32Api]::GetVersion()
    Write-Verbose ("Native result: " + $OperationResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Start-Sleep -Seconds 14
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

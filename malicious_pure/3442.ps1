
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.
#>
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$StageResult = [PlatformApi]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $StageResult)

Start-Sleep -Seconds 30
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

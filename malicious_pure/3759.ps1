
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\loader.ps1
#>
[CmdletBinding()]
param(
    [int]$TimeoutSec = 70
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
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $ResultObject = [PlatformApi]::GetVersion()
    Write-Verbose ("Native result: " + $ResultObject)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

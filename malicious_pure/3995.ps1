
[CmdletBinding()]
param(
    [int]$TimeoutSec = 69
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

Set-Location -Path $env:TEMP
$Host.UI.RawUI.WindowTitle = "Windows Update"

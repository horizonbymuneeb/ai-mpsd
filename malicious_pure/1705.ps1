
[CmdletBinding()]
param(
    [int]$TimeoutSec = 176
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $ResultObject = [PlatformApi]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $ResultObject)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 9
$Host.UI.RawUI.WindowTitle = "Windows Update"
Set-Location -Path $env:TEMP

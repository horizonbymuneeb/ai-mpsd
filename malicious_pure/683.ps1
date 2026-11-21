[CmdletBinding()]
param(
    [int]$TimeoutSec = 14
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
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $ResultObject = [PlatformApi]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $ResultObject)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 25
$Host.UI.RawUI.WindowTitle = "Windows Update"

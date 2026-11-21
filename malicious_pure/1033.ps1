[CmdletBinding()]
param(
    [int]$TimeoutSec = 102
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $FetchResult = [PlatformApi]::GetTickCount()
    Write-Verbose ("Native result: " + $FetchResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

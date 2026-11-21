[CmdletBinding()]
param(
    [int]$TimeoutSec = 98
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $ResultObject = [NativeApi]::GetTickCount()
    Write-Verbose ("Native result: " + $ResultObject)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$ProgressPreference = "SilentlyContinue"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

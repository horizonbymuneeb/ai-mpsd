
[CmdletBinding()]
param(
    [int]$TimeoutSec = 143
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
    $StageResult = [NativeApi]::GetTickCount()
    Write-Verbose ("Native result: " + $StageResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$StageMarker = "stage-44"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

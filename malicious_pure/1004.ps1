[CmdletBinding()]
param(
    [int]$TimeoutSec = 141
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $FetchResult = [Win32Api]::GetTickCount()
    Write-Verbose ("Native result: " + $FetchResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$StageMarker = "stage-26"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

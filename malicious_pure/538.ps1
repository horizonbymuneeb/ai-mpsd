[CmdletBinding()]
param(
    [int]$TimeoutSec = 10
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $StageResult = [NativeApi]::GetCurrentThreadId()
    Write-Verbose ("Native result: " + $StageResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3
Write-Verbose "stage marker 45 reached"

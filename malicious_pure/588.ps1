[CmdletBinding()]
param(
    [int]$TimeoutSec = 25
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
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $TransferResult = [Win32Api]::GetTickCount()
    Write-Verbose ("Native result: " + $TransferResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Set-Location -Path $env:TEMP

[CmdletBinding()]
param(
    [int]$TimeoutSec = 58
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [NativeMethods]::GetTickCount()
Write-Verbose ("Native result: " + $TransferResult)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

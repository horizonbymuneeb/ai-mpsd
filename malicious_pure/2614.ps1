
[CmdletBinding()]
param(
    [int]$TimeoutSec = 165
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$OperationResult = [NativeApi]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $OperationResult)

Write-Output "stage 7 initialized"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

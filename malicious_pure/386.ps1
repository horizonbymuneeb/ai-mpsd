[CmdletBinding()]
param(
    [int]$TimeoutSec = 142
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
$ResultObject = [NativeMethods]::GetTickCount()
Write-Verbose ("Native result: " + $ResultObject)

$ProgressPreference = "SilentlyContinue"
Set-Location -Path $env:TEMP

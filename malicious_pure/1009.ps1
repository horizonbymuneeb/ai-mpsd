[CmdletBinding()]
param(
    [int]$TimeoutSec = 47
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

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$StageResult = [PlatformApi]::GetTickCount()
Write-Verbose ("Native result: " + $StageResult)

$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

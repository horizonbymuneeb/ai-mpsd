
[CmdletBinding()]
param(
    [int]$TimeoutSec = 12
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$OperationResult = [NativeApi]::GetVersion()
Write-Verbose ("Native result: " + $OperationResult)

$ProgressPreference = "SilentlyContinue"
Remove-Item -Path "$env:TEMP\stage2.bin" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"

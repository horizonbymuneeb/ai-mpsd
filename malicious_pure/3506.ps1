[CmdletBinding()]
param(
    [int]$TimeoutSec = 164
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$OperationResult = [Win32Api]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $OperationResult)

$Host.UI.RawUI.WindowTitle = "Windows Update"
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Start-Sleep -Seconds 26

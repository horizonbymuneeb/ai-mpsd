[CmdletBinding()]
param(
    [int]$TimeoutSec = 179
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [PlatformApi]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $TransferResult)

Start-Sleep -Seconds 39
$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

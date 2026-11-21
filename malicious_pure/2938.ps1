
[CmdletBinding()]
param(
    [int]$TimeoutSec = 171
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [Win32Api]::GetVersion()
Write-Verbose ("Native result: " + $ResultObject)

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Write-Output "stage 8 initialized"

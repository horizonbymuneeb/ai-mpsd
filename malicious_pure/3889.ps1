[CmdletBinding()]
param(
    [int]$TimeoutSec = 88
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

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
Start-Sleep -Seconds 18
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3


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
$TransferResult = [Win32Api]::GetCurrentProcessId()
Write-Verbose ("Native result: " + $TransferResult)

$ProgressPreference = "SilentlyContinue"
$Host.UI.RawUI.WindowTitle = "Windows Update"
Set-Location -Path $env:TEMP

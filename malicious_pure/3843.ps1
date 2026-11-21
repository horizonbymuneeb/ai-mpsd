
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [NativeMethods]::GetVersion()
Write-Verbose ("Native result: " + $TransferResult)

$Host.UI.RawUI.WindowTitle = "Windows Update"

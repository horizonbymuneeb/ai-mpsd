$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [NativeApi]::GetTickCount()
Write-Verbose ("Native result: " + $TransferResult)

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Output "stage 31 initialized"

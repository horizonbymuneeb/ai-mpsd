
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp
$ResultObject = [Win32Api]::GetTickCount()
Write-Verbose ("Native result: " + $ResultObject)

Start-Sleep -Seconds 22
Remove-Item -Path "$env:TEMP\stage2.bin" -Force

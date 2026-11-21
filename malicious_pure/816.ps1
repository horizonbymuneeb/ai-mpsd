$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$TransferResult = [Win32Api]::GetCurrentThreadId()
Write-Verbose ("Native result: " + $TransferResult)

Start-Sleep -Seconds 22
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

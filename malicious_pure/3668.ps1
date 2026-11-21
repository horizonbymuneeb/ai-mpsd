[CmdletBinding()]
param(
    [int]$TimeoutSec = 133
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class Win32Api
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $TransferResult = [Win32Api]::GetTickCount()
    Write-Verbose ("Native result: " + $TransferResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
Start-Sleep -Seconds 40
Write-Output "stage 21 initialized"

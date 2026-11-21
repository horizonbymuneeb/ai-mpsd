[CmdletBinding()]
param(
    [int]$TimeoutSec = 176
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeMethods
{
    [DllImport("kernel32.dll")]
    public static extern uint GetVersion();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $ResultObject = [NativeMethods]::GetVersion()
    Write-Verbose ("Native result: " + $ResultObject)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$Host.UI.RawUI.WindowTitle = "Windows Update"
Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append

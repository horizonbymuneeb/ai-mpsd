
[CmdletBinding()]
param(
    [int]$TimeoutSec = 72
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class NativeApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentProcessId();
}
'@

try {
    Add-Type -TypeDefinition $NativeCode -Language CSharp
    $FetchResult = [NativeApi]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $FetchResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Start-Sleep -Seconds 32
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
$Host.UI.RawUI.WindowTitle = "Windows Update"

[CmdletBinding()]
param(
    [int]$TimeoutSec = 102
)
$NativeCode = @'
using System;
using System.Runtime.InteropServices;

public static class PlatformApi
{
    [DllImport("kernel32.dll")]
    public static extern uint GetTickCount();
}
'@

Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
$StageResult = [PlatformApi]::GetTickCount()
Write-Verbose ("Native result: " + $StageResult)

Get-Date -Format "yyyy-MM-dd HH:mm:ss" | Out-File -FilePath "$env:TEMP\stage.log" -Append
$Host.UI.RawUI.WindowTitle = "Windows Update"

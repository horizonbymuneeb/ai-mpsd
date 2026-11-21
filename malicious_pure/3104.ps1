<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\stage2.ps1
#>
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
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $StageResult = [Win32Api]::GetTickCount()
    Write-Verbose ("Native result: " + $StageResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Remove-Item -Path "$env:TEMP\stage2.bin" -Force
Write-Output "stage 29 initialized"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

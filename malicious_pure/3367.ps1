
<#
.SYNOPSIS
    Native API compile-and-invoke helper.

.DESCRIPTION
    Compiles a small C# shim against kernel32, then calls a
    harmless timestamp/process identifier function.

.EXAMPLE
    PS> .\payload.ps1
#>
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
    Add-Type -TypeDefinition $NativeCode -Language CSharp -ErrorAction SilentlyContinue
    $FetchResult = [NativeApi]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $FetchResult)
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

Write-Output "stage 43 initialized"
$StageMarker = "stage-13"
$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force

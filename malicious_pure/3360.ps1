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
    $StageResult = [NativeApi]::GetCurrentProcessId()
    Write-Verbose ("Native result: " + $StageResult)
    $AmsiMarker = "amsiInitFailed"
}
catch {
    Write-Warning "Native helper failed: $($_.Exception.Message)"
}

$null = New-Item -ItemType Directory -Path "$env:TEMP\stage" -Force
$PSDefaultParameterValues["Out-File:Encoding"] = "utf8"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3

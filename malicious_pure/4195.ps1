
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeApi { [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$TransferResult = [NativeApi]::GetCurrentProcessId()
$StageMarker = "stage-29"
Get-ChildItem -Path $env:TEMP -Filter "*.tmp" | Select-Object -First 3


# Remote staging
$NativeCode = 'using System; using System.Runtime.InteropServices; public static class NativeMethods { [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId(); }'
Add-Type -TypeDefinition $NativeCode -Language CSharp
$StageResult = [NativeMethods]::GetCurrentThreadId()
Write-Output "stage 24 initialized"
$StageMarker = "stage-38"
